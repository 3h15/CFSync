defmodule CFSync.Store.TableTest do
  use ExUnit.Case, async: true

  doctest CFSync.Store.Table

  alias CFSync.Store.Table
  alias CFSync.Entry
  alias CFSync.Asset

  test "new/1 creates a named ETS table using name param" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    reference = Table.new(name)
    assert :ets.whereis(name) == reference
  end

  test "new/1 creates a protected set table, with read concurrency and no write concurrency" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    reference = Table.new(name)

    info = :ets.info(reference)

    assert Keyword.fetch!(info, :type) == :set
    assert Keyword.fetch!(info, :protection) == :protected
    assert Keyword.fetch!(info, :read_concurrency) == true
    assert Keyword.fetch!(info, :write_concurrency) == false
  end

  test "put/2 inserts entries in table" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    reference = Table.new(name)

    entry = %{id: id} = create_page_entry()
    Table.put(reference, entry)

    assert [{_, _, %Entry{id: ^id}}] = :ets.lookup(reference, {:entry, entry.id})
  end

  test "put/2 inserts assets in table" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    reference = Table.new(name)

    asset = %{id: id} = create_asset()
    Table.put(reference, asset)

    assert [{_, _, %Asset{id: ^id}}] = :ets.lookup(reference, {:asset, asset.id})
  end

  test "get_entry/2 get entry from table" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    reference = Table.new(name)

    entry = %{id: id} = create_page_entry()
    Table.put(reference, entry)

    assert Table.get_entry(reference, id) == entry
  end

  test "get_entries_for_content_type/2 get filtered entries from table" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    reference = Table.new(name)

    entry_1 = %{id: id_1} = create_page_entry()
    entry_2 = %{id: id_2} = create_page_entry()
    entry_3 = %{id: id_3} = create_simple_page_entry()

    Table.put(reference, entry_1)
    Table.put(reference, entry_2)
    Table.put(reference, entry_3)

    page_entries = Table.get_entries_for_content_type(reference, :page)

    assert length(page_entries) == 2

    ids = Enum.map(page_entries, & &1.id)
    assert id_1 in ids
    assert id_2 in ids
    assert id_3 not in ids
  end

  test "get_asset/2 get asset from table" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    reference = Table.new(name)

    asset = %{id: id} = create_asset()
    Table.put(reference, asset)

    assert Table.get_asset(reference, id) == asset
  end

  defp create_page_entry() do
    %Entry{
      id: Faker.String.base64(10),
      revision: Faker.random_between(1, 1000),
      content_type: :page,
      fields: CFSyncTest.Fields.Page.new(%{}, "en")
    }
  end

  defp create_simple_page_entry() do
    %Entry{
      id: Faker.String.base64(10),
      revision: Faker.random_between(1, 1000),
      content_type: :simple_page,
      fields: CFSyncTest.Fields.SimplePage.new(%{}, "en")
    }
  end

  defp create_asset() do
    %Asset{
      id: Faker.String.base64(10),
      content_type: Faker.String.base64(10),
      title: Faker.String.base64(10),
      description: Faker.String.base64(10),
      file_name: Faker.String.base64(10),
      url: Faker.Internet.url(),
      width: 0,
      height: 0,
      size: 0
    }
  end
end
