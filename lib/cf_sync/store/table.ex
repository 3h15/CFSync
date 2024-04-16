defmodule CFSync.Store.Table do
  @moduledoc false

  alias CFSync.Entry
  alias CFSync.Asset
  alias CFSync.Link

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
  def put(ref, %Entry{id: id, locale: locale} = entry),
    do: put(ref, :entry, id, locale, entry.content_type, entry)

  def put(ref, %Asset{id: id, locale: locale} = asset),
    do: put(ref, :asset, id, locale, :asset, asset)

  @spec get_entry(:ets.tid(), binary(), atom()) :: nil | Entry.t()
  def get_entry(ref, entry_id, locale) do
    case :ets.lookup(ref, {:entry, entry_id, locale}) do
      [{_key, _content_type, entry}] -> entry
      _ -> nil
    end
  end

  @spec get_asset(:ets.tid(), binary(), atom()) :: nil | Asset.t()
  def get_asset(ref, asset_id, locale) do
    case :ets.lookup(ref, {:asset, asset_id, locale}) do
      [{_key, _content_type, asset}] -> asset
      _ -> nil
    end
  end

  @spec get_assets(:ets.tid(), atom()) :: list
  def get_assets(ref, locale) do
    records = :ets.match_object(ref, {{:asset, :_, locale}, :_, :_})

    for {_key, _content_type, asset} <- records do
      asset
    end
  end

  @spec get_entries(:ets.tid(), atom()) :: list
  def get_entries(ref, locale) do
    records = :ets.match_object(ref, {{:entry, :_, locale}, :_, :_})

    for {_key, _content_type, entry} <- records do
      entry
    end
  end

  @spec get_entries_for_content_type(:ets.tid(), locale :: atom, content_type :: atom) :: list
  def get_entries_for_content_type(ref, locale, content_type) do
    records = :ets.match_object(ref, {{:_, :_, locale}, content_type, :_})

    for {_key, _content_type, entry} <- records do
      entry
    end
  end

  # @spec get_link_target(:ets.tid(), Link.t()) :: nil | Entry.t() | Asset.t()
  # def get_link_target(store, %Link{type: :entry, id: id}) do
  #   # get_entry(store, id)
  # end

  # def get_link_target(store, %Link{type: :asset, id: id}) do
  #   # get_asset(store, id)
  # end

  @spec delete_entry(:ets.tid(), binary(), atom()) :: true
  def delete_entry(ref, entry_id, entry_locale) do
    :ets.delete(ref, {:entry, entry_id, entry_locale})
  end

  @spec delete_asset(:ets.tid(), binary(), atom()) :: true
  def delete_asset(ref, asset_id, asset_locale) do
    :ets.delete(ref, {:asset, asset_id, asset_locale})
  end

  defp put(ref, type, id, locale, content_type, record) do
    key = {type, id, locale}
    :ets.insert(ref, {key, content_type, record})
  end
end
