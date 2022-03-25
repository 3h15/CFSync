defmodule CFSync.Store.State do
  @default_initial_sync_interval 30
  @default_delta_sync_interval 5000

  defstruct([
    :name,
    :table_reference,
    :initial_sync_interval,
    :delta_sync_interval,
    :next_url,
    next_url_type: :next_page,
    auto_tick: true
  ])

  @type t() :: %__MODULE__{
          name: atom(),
          table_reference: :ets.tid(),
          initial_sync_interval: integer(),
          delta_sync_interval: integer(),
          next_url: nil | binary(),
          next_url_type: :next_page | :next_sync,
          auto_tick: boolean()
        }

  @spec new(atom, :ets.tid(), keyword) :: CFSync.Store.State.t()
  def new(name, table_reference, opts \\ [])
      when is_atom(name) and is_list(opts) do
    initial_sync_interval =
      Keyword.get(opts, :initial_sync_interval, @default_initial_sync_interval)

    delta_sync_interval = Keyword.get(opts, :delta_sync_interval, @default_delta_sync_interval)

    auto_tick = Keyword.get(opts, :auto_tick, true)

    %__MODULE__{
      name: name,
      table_reference: table_reference,
      initial_sync_interval: initial_sync_interval,
      delta_sync_interval: delta_sync_interval,
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
end
