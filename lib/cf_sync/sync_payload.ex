defmodule CFSync.SyncPayload do
  @moduledoc false

  alias CFSync.Entry
  alias CFSync.Asset

  @type delta() :: {:upsert, Entry.t() | Asset.t()} | {:delete_asset | :delete_entry, binary()}

  defstruct next_url: "",
            next_url_type: :next_page,
            deltas: []

  @type t() :: %__MODULE__{
          next_url: binary(),
          next_url_type: :next_page | :next_sync,
          deltas: list(delta())
        }

  @spec new(%{:items => [], optional(any) => any}, map, binary) ::
          CFSync.SyncPayload.t()
  def new(%{"nextPageUrl" => url, "items" => items}, content_types, locale)
      when is_list(items) and is_binary(locale) do
    %__MODULE__{
      next_url: url,
      next_url_type: :next_page,
      deltas: deltas(items, content_types, locale)
    }
  end

  def new(%{"nextSyncUrl" => url, "items" => items}, content_types, locale)
      when is_list(items) and is_binary(locale) do
    %__MODULE__{
      next_url: url,
      next_url_type: :next_sync,
      deltas: deltas(items, content_types, locale)
    }
  end

  defp deltas(items, content_types, locale) do
    for %{"sys" => %{"id" => id, "type" => type}} = item <- items do
      case type do
        "Asset" ->
          {:upsert, Asset.new(item, locale)}

        "Entry" ->
          {:upsert, Entry.new(item, content_types, locale)}

        "DeletedAsset" ->
          {:delete_asset, id}

        "DeletedEntry" ->
          {:delete_entry, id}
      end
    end
  end
end
