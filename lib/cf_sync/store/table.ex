defmodule CFSync.Store.Table do
  alias CFSync.Entry
  alias CFSync.Asset

  @spec new(atom) :: :ets.tid()
  def new(name) when is_atom(name) do
    :ets.new(name, [
      :named_table,
      :set,
      :protected,
      write_concurrency: false,
      read_concurrency: true
    ])

    :ets.whereis(name)
  end

  @spec put(:ets.tid(), CFSync.Asset.t() | CFSync.Entry.t()) :: true
  def put(ref, %Entry{id: id} = entry), do: put(ref, :entry, id, entry.content_type, entry)
  def put(ref, %Asset{id: id} = asset), do: put(ref, :asset, id, :asset, asset)

  @spec get_entry(:ets.tid(), binary()) :: nil | Entry.t()
  def get_entry(ref, entry_id) do
    case :ets.lookup(ref, {:entry, entry_id}) do
      [{_key, _content_type, entry}] -> entry
      _ -> nil
    end
  end

  @spec get_asset(:ets.tid(), binary()) :: nil | Asset.t()
  def get_asset(ref, asset_id) do
    case :ets.lookup(ref, {:asset, asset_id}) do
      [{_key, _content_type, asset}] -> asset
      _ -> nil
    end
  end

  def get_entries_for_content_type(ref, content_type) do
    records = :ets.match_object(ref, {:_, content_type, :_})

    for {_key, _content_type, entry} <- records do
      entry
    end
  end

  defp put(ref, type, id, content_type, record) do
    key = {type, id}
    :ets.insert(ref, {key, content_type, record})
  end
end
