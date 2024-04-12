defmodule CFSync.SyncPayload do
  @moduledoc false

  @type delta() :: {:upsert, map() | map()} | {:delete_asset | :delete_entry, binary()}

  defstruct next_url: "",
            next_url_type: :next_page,
            deltas: []

  @type t() :: %__MODULE__{
          next_url: binary(),
          next_url_type: :next_page | :next_sync,
          deltas: list(delta())
        }

  @spec new(%{:items => [], optional(any) => any}) :: CFSync.SyncPayload.t()
  def new(%{"nextPageUrl" => url, "items" => items}) do
    %__MODULE__{
      next_url: url,
      next_url_type: :next_page,
      deltas: deltas(items)
    }
  end

  def new(%{"nextSyncUrl" => url, "items" => items}) do
    %__MODULE__{
      next_url: url,
      next_url_type: :next_sync,
      deltas: deltas(items)
    }
  end

  defp deltas(items) do
    for %{"sys" => %{"id" => id, "type" => type}} = item <- items do
      case type do
        "Asset" ->
          {:upsert_asset, item}

        "Entry" ->
          {:upsert_entry, item}

        "DeletedAsset" ->
          {:delete_asset, id}

        "DeletedEntry" ->
          {:delete_entry, id}
      end
    end
  end
end
