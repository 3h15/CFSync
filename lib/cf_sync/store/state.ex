defmodule CFSync.Store.State do
  @moduledoc false

  @default_root_url "https://cdn.contentful.com/"
  @default_locale "en-US"
  @default_initial_sync_interval 30
  @default_delta_sync_interval 5000

  defstruct([
    :name,
    :delivery_token,
    :locale,
    :table_reference,
    :initial_sync_interval,
    :delta_sync_interval,
    :next_url,
    next_url_type: :next_page,
    auto_tick: true
  ])

  @type t() :: %__MODULE__{
          name: atom(),
          delivery_token: binary,
          locale: binary(),
          table_reference: :ets.tid(),
          initial_sync_interval: integer(),
          delta_sync_interval: integer(),
          next_url: nil | binary(),
          next_url_type: :next_page | :next_sync,
          auto_tick: boolean()
        }

  @spec new(atom, binary, binary, :ets.tid(), keyword) :: CFSync.Store.State.t()
  def new(name, space_id, delivery_token, table_reference, opts \\ []) do
    root_url = Keyword.get(opts, :root_url, @default_root_url)
    locale = Keyword.get(opts, :locale, @default_locale)

    initial_sync_interval =
      Keyword.get(opts, :initial_sync_interval, @default_initial_sync_interval)

    delta_sync_interval = Keyword.get(opts, :delta_sync_interval, @default_delta_sync_interval)
    auto_tick = Keyword.get(opts, :auto_tick, true)

    %__MODULE__{
      name: name,
      delivery_token: delivery_token,
      locale: locale,
      table_reference: table_reference,
      initial_sync_interval: initial_sync_interval,
      delta_sync_interval: delta_sync_interval,
      next_url: initial_url(root_url, space_id),
      auto_tick: auto_tick
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
