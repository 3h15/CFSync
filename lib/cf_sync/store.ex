defmodule CFSync.Store do
  @moduledoc false

  require Logger

  use GenServer

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

  @spec start_link(atom, binary, binary, keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(name, space_id, delivery_token, opts \\ []) do
    init_args = [
      {:name, name},
      {:space_id, space_id},
      {:delivery_token, delivery_token} | opts
    ]

    GenServer.start_link(__MODULE__, init_args, name: name)
  end

  @impl true
  @spec init(keyword) :: {:ok, State.t()}
  def init(init_args) do
    name = Keyword.fetch!(init_args, :name)
    space_id = Keyword.fetch!(init_args, :space_id)
    delivery_token = Keyword.fetch!(init_args, :delivery_token)
    table_reference = Table.new(name)

    state =
      name
      |> State.new(space_id, delivery_token, table_reference, init_args)
      |> schedule_tick(@delay_before_start)

    {:ok, state}
  end

  @impl true
  def handle_info(:sync, %State{next_url: url, delivery_token: token, locale: locale} = state) do
    case(@http_client_module.fetch(url, token)) do
      {:ok, data} ->
        # We got a response, handle it
        payload = SyncPayload.new(data, locale)

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

  defp update_url(s, %SyncPayload{next_url_type: :next_page, next_url: url} = _payload) do
    State.update(s, url, :next_page)
  end

  defp update_url(s, %SyncPayload{next_url_type: :next_sync, next_url: url} = _payload) do
    State.update(s, url, :next_sync)
  end

  defp update_table(state, %SyncPayload{deltas: deltas}) do
    for delta <- deltas do
      case delta do
        {:upsert, item} -> Table.put(state.table_reference, item)
        {:delete_asset, asset_id} -> Table.delete_asset(state.table_reference, asset_id)
        {:delete_entry, entry_id} -> Table.delete_entry(state.table_reference, entry_id)
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
      Process.send_after(self(), :sync, delay)
    end

    state
  end

  defp schedule_next_tick(%State{next_url_type: :next_page} = state),
    do: schedule_next_tick(state, state.initial_sync_interval)

  defp schedule_next_tick(%State{next_url_type: :next_sync} = state),
    do: schedule_next_tick(state, state.delta_sync_interval)

  defp schedule_next_tick(state, delay) do
    state
    |> schedule_tick(delay)
  end
end
