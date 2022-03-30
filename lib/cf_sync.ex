defmodule CFSync do
  alias CFSync.Store
  alias CFSync.Space
  alias CFSync.Entry
  alias CFSync.Asset
  alias CFSync.Link

  @spec start_link(atom, keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(name, opts) when is_atom(name) and is_list(opts),
    do: Store.start_link(name, opts)

  @spec new_space(binary, binary, binary) :: Space.t()
  def new_space(root_url, space_id, token), do: Space.new(root_url, space_id, token)

  @spec from(atom) :: :ets.tid()
  def from(name), do: Store.Table.get_table_reference_for_name(name)

  @spec get_entries(:ets.tid()) :: [Entry.t()]
  def get_entries(table_ref) when not is_atom(table_ref), do: Store.Table.get_entries(table_ref)

  @spec get_entries_for_content_type(:ets.tid(), atom) :: [Entry.t()]
  def get_entries_for_content_type(table_ref, content_type)
      when not is_atom(table_ref) and is_atom(content_type),
      do: Store.Table.get_entries_for_content_type(table_ref, content_type)

  @spec get_entry(:ets.tid(), binary) :: nil | Entry.t()
  def get_entry(table_ref, id) when not is_atom(table_ref) and is_binary(id),
    do: Store.Table.get_entry(table_ref, id)

  @spec get_assets(:ets.tid()) :: [Asset.t()]
  def get_assets(table_ref) when not is_atom(table_ref), do: Store.Table.get_assets(table_ref)

  @spec get_asset(:ets.tid(), binary) :: nil | Asset.t()
  def get_asset(table_ref, id) when not is_atom(table_ref) and is_binary(id),
    do: Store.Table.get_asset(table_ref, id)

  @spec get_link_target(:ets.tid(), Link.t()) :: nil | Entry.t() | Asset.t()
  def get_link_target(table_ref, %Link{} = link) when not is_atom(table_ref),
    do: Store.Table.get_link_target(table_ref, link)
end
