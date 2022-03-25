defmodule CFSync.Store.State do
  @default_initial_sync_interval 30
  @default_delta_sync_interval 5000

  defstruct([:name, :table_reference, :initial_sync_interval, :delta_sync_interval, :next_url])

  @type t() :: %__MODULE__{
          name: atom(),
          table_reference: reference(),
          initial_sync_interval: integer(),
          delta_sync_interval: integer(),
          next_url: nil | binary()
        }

  def new(name, table_reference, opts \\ [])
      when is_atom(name) and is_reference(table_reference) and is_list(opts) do
    initial_sync_interval =
      Keyword.get(opts, :initial_sync_interval, @default_initial_sync_interval)

    delta_sync_interval = Keyword.get(opts, :delta_sync_interval, @default_delta_sync_interval)

    %__MODULE__{
      name: name,
      table_reference: table_reference,
      initial_sync_interval: initial_sync_interval,
      delta_sync_interval: delta_sync_interval
    }
  end

  def update(%__MODULE__{} = this, url) when is_binary(url) do
    %__MODULE__{
      this
      | next_url: url
    }
  end
end
