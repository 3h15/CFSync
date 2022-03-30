defmodule CFSync.Store.Table do
  alias CFSync.Entry
  alias CFSync.Asset

  @spec new(atom) :: :ets.tid()
  def new(name) when is_atom(name) do
    :ets.new(name, [
      :named_table,
      :ordered_set,
      :protected,
      write_concurrency: false,
      read_concurrency: true
    ])

    case :ets.whereis(name) do
      # coveralls-ignore-start
      :undefined ->
        raise "Unable to create ETS table"

      # coveralls-ignore-stop

      ref ->
        ref
    end
  end

  @spec get_table_reference_for_name(atom) :: :ets.tid()
  def get_table_reference_for_name(name) do
    case :ets.whereis(name) do
      # coveralls-ignore-start
      :undefined ->
        raise "Could not find ETS table"

      # coveralls-ignore-stop

      ref ->
        ref
    end
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

  @spec get_assets(:ets.tid()) :: list
  def get_assets(ref) do
    records = :ets.match_object(ref, {{:asset, :_}, :_, :_})

    for {_key, _content_type, asset} <- records do
      asset
    end
  end

  @spec get_entries(:ets.tid()) :: list
  def get_entries(ref) do
    records = :ets.match_object(ref, {{:entry, :_}, :_, :_})

    for {_key, _content_type, entry} <- records do
      entry
    end
  end

  @spec get_entries_for_content_type(:ets.tid(), :atom) :: list
  def get_entries_for_content_type(ref, content_type) do
    records = :ets.match_object(ref, {:_, content_type, :_})

    for {_key, _content_type, entry} <- records do
      entry
    end
  end

  @spec delete_entry(:ets.tid(), binary()) :: true
  def delete_entry(ref, entry_id) do
    :ets.delete(ref, {:entry, entry_id})
  end

  @spec delete_asset(:ets.tid(), binary()) :: true
  def delete_asset(ref, asset_id) do
    :ets.delete(ref, {:asset, asset_id})
  end

  defp put(ref, type, id, content_type, record) do
    key = {type, id}
    :ets.insert(ref, {key, content_type, record})
  end
end
