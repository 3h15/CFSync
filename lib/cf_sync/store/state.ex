defmodule CFSync.Store.State do
  @moduledoc false

  @default_root_url "https://cdn.contentful.com/"
  @default_locale "en-US"
  @default_initial_sync_interval 30
  @default_delta_sync_interval 5000

  defstruct([
    :name,
    :delivery_token,
    :content_types,
    :locale,
    :table_reference,
    :current_timer,
    :initial_sync_interval,
    :delta_sync_interval,
    :next_url,
    next_url_type: :next_page,
    auto_tick: true,
    invalidation_callbacks: [],
    dump_name: nil
  ])

  @type t() :: %__MODULE__{
          name: atom,
          delivery_token: binary,
          content_types: map,
          locale: binary,
          current_timer: reference() | nil,
          table_reference: :ets.tid(),
          initial_sync_interval: integer,
          delta_sync_interval: integer,
          next_url: nil | binary,
          next_url_type: :next_page | :next_sync,
          auto_tick: boolean,
          invalidation_callbacks: [function],
          dump_name: binary | nil
        }

  @spec new(atom, binary, binary, map, :ets.tid(), keyword) :: CFSync.Store.State.t()
  def new(name, space_id, delivery_token, content_types, table_reference, opts \\ []) do
    root_url = Keyword.get(opts, :root_url, @default_root_url)
    locale = Keyword.get(opts, :locale, @default_locale)

    initial_sync_interval =
      Keyword.get(opts, :initial_sync_interval, @default_initial_sync_interval)

    delta_sync_interval = Keyword.get(opts, :delta_sync_interval, @default_delta_sync_interval)
    auto_tick = Keyword.get(opts, :auto_tick, true)

    invalidation_callbacks = Keyword.get(opts, :invalidation_callbacks, [])

    %__MODULE__{
      name: name,
      delivery_token: delivery_token,
      content_types: content_types,
      locale: locale,
      current_timer: nil,
      table_reference: table_reference,
      initial_sync_interval: initial_sync_interval,
      delta_sync_interval: delta_sync_interval,
      next_url: initial_url(root_url, space_id),
      auto_tick: auto_tick,
      invalidation_callbacks: invalidation_callbacks
    }
  end

  @spec new_from_dump(atom, true | binary, map, :ets.tid(), keyword) :: CFSync.Store.State.t()
  def new_from_dump(name, dump, content_types, table_reference, opts \\ []) do
    locale = Keyword.get(opts, :locale, @default_locale)

    dump_name = if dump == true, do: "default", else: dump

    %__MODULE__{
      name: name,
      delivery_token: "",
      content_types: content_types,
      locale: locale,
      current_timer: nil,
      table_reference: table_reference,
      initial_sync_interval: 0,
      delta_sync_interval: 0,
      next_url: "",
      auto_tick: true,
      invalidation_callbacks: [],
      dump_name: dump_name
    }
  end

  def update(%__MODULE__{} = this, url, url_type)
      when is_binary(url) and url_type in [:next_page, :next_sync] do
    %__MODULE__{
      this
      | next_url: url,
        next_url_type: url_type
    }
  end

  defp initial_url(root_url, space_id), do: "#{root_url}spaces/#{space_id}/sync/?initial=true"
end
