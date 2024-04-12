defmodule CFSync.Store do
  @moduledoc false

  require Logger

  use GenServer

  alias CFSync.Asset
  alias CFSync.Entry
  alias CFSync.Store.State
  alias CFSync.Store.Table
  alias CFSync.SyncPayload

  @http_client_module Application.compile_env(
                        :cf_sync,
                        :http_client_module,
                        CFSync.HTTPClient.HTTPoison
                      )

  # Delay between init/1 call and first sync request. This gives some time the parent
  # process to continue initializing. For example, tests rely on it to setup mocks
  # before first request. Do not lower it too much to avoid make tests brittle.
  @delay_before_start 10

  @spec start_link(atom, binary, binary, map, keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(name, space_id, delivery_token, content_types, opts \\ []) do
    init_args = [
      {:name, name},
      {:space_id, space_id},
      {:delivery_token, delivery_token},
      {:content_types, content_types} | opts
    ]

    GenServer.start_link(__MODULE__, init_args, name: name)
  end

  @impl true
  @spec init(keyword) :: {:ok, State.t()}
  def init(init_args) do
    name = Keyword.fetch!(init_args, :name)
    content_types = Keyword.fetch!(init_args, :content_types)
    table_reference = Table.new(name)

    state =
      case Keyword.get(init_args, :use_dump_file) do
        dump when dump == true or is_binary(dump) ->
          State.new_from_dump(
            name,
            dump,
            content_types,
            table_reference,
            init_args
          )

        _ ->
          space_id = Keyword.fetch!(init_args, :space_id)
          delivery_token = Keyword.fetch!(init_args, :delivery_token)

          State.new(
            name,
            space_id,
            delivery_token,
            content_types,
            table_reference,
            init_args
          )
      end

    state = schedule_tick(state, @delay_before_start)

    {:ok, state}
  end

  @impl true
  def handle_info(
        :sync,
        %State{
          next_url: url,
          delivery_token: token,
          dump_name: nil
        } = state
      ) do
    case(@http_client_module.fetch(url, token)) do
      {:ok, data} ->
        # We got a response, handle it
        payload = SyncPayload.new(data)

        {:noreply,
         state
         |> update_url(payload)
         |> update_table(payload)
         |> schedule_next_tick()}

      {:rate_limited, delay} ->
        # We've been bounced, keep state and wait for delay + 1 sec

        {:noreply,
         state
         |> schedule_tick(1000 + delay * 1000)}

      {:error, _} ->
        # We encountered an error, log and exit
        Logger.error("Sync request error, exiting.")
        {:stop, :normal, nil}
    end
  end

  def handle_info(
        :sync,
        %State{
          dump_name: dump_name
        } = state
      ) do
    state =
      case CfSync.Tasks.Utils.read_dump(dump_name) do
        {:ok, pages} ->
          Enum.reduce(pages, state, fn page, state ->
            payload = SyncPayload.new(page)
            update_table(state, payload)
          end)

        _ ->
          raise "Unable to read CFSync dump file \"#{dump_name}\""
      end

    {:noreply, state}
  end

  @impl true
  def handle_cast(:force_sync, %State{} = state) do
    {:noreply, force_tick(state)}
  end

  @spec force_sync(atom) :: :ok
  def force_sync(name) do
    GenServer.cast(name, :force_sync)
  end

  defp update_url(s, %SyncPayload{next_url_type: :next_page, next_url: url} = _payload) do
    State.update(s, url, :next_page)
  end

  defp update_url(s, %SyncPayload{next_url_type: :next_sync, next_url: url} = _payload) do
    State.update(s, url, :next_sync)
  end

  defp update_table(
         %{
           table_reference: store,
           content_types: content_types,
           locale: locale
         } = state,
         %SyncPayload{deltas: deltas}
       ) do
    for delta <- deltas do
      case delta do
        {:upsert_asset, item} ->
          asset = Asset.new(item, locale, store)
          Table.put(state.table_reference, asset)

        {:upsert_entry, item} ->
          entry = Entry.new(item, content_types, locale, store)
          Table.put(state.table_reference, entry)

        {:delete_asset, asset_id} ->
          Table.delete_asset(state.table_reference, asset_id)

        {:delete_entry, entry_id} ->
          Table.delete_entry(state.table_reference, entry_id)
      end
    end

    if deltas != [] do
      for cb <- state.invalidation_callbacks do
        cb.()
      end
    end

    state
  end

  defp schedule_tick(state, delay) do
    if state.auto_tick do
      timer = Process.send_after(self(), :sync, delay)
      %State{state | current_timer: timer}
    else
      state
    end
  end

  defp schedule_next_tick(%State{next_url_type: :next_page} = state),
    do: schedule_next_tick(state, state.initial_sync_interval)

  defp schedule_next_tick(%State{next_url_type: :next_sync} = state),
    do: schedule_next_tick(state, state.delta_sync_interval)

  defp schedule_next_tick(state, delay) do
    state
    |> schedule_tick(delay)
  end

  # Do not force tick during init
  defp force_tick(%State{next_url_type: :next_page} = state), do: state

  defp force_tick(state) do
    if Process.cancel_timer(state.current_timer) do
      schedule_tick(state, 0)
    else
      # Timer was not found, it means it is expired and the process has a
      # tick message waiting in the inbox. Let the process continue to that tick.
      state
    end
  end
end
