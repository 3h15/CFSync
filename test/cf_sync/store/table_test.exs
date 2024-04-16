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

  test "new/1 creates a protected ordered_set table, with read concurrency and no write concurrency" do
    reference = create_table()
    info = :ets.info(reference)

    assert Keyword.fetch!(info, :type) == :ordered_set
    assert Keyword.fetch!(info, :protection) == :protected
    assert Keyword.fetch!(info, :read_concurrency) == true
    assert Keyword.fetch!(info, :write_concurrency) == false
  end

  test "put/2 inserts entries in table" do
    reference = create_table()
    entry = create_page_entry()
    Table.put(reference, entry)
    assert [{_, _, ^entry}] = :ets.lookup(reference, {:entry, entry.id, entry.locale})
  end

  test "put/2 inserts assets in table" do
    reference = create_table()
    asset = create_asset()
    Table.put(reference, asset)
    assert [{_, _, ^asset}] = :ets.lookup(reference, {:asset, asset.id, asset.locale})
  end

  test "get_entry/2 get entry from table" do
    reference = create_table()
    entry = create_page_entry()
    Table.put(reference, entry)
    assert Table.get_entry(reference, entry.id, entry.locale) == entry
  end

  test "delete_entry/2 deletes entry from table" do
    reference = create_table()
    entry_1 = create_page_entry()
    entry_2 = create_page_entry()
    Table.put(reference, entry_1)
    Table.put(reference, entry_2)
    Table.delete_entry(reference, entry_1.id, entry_1.locale)

    assert [{_, _, ^entry_2}] = :ets.lookup(reference, {:entry, entry_2.id, entry_2.locale})
    assert [] = :ets.lookup(reference, {:entry, entry_1.id, entry_1.locale})
  end

  test "get_entries_for_content_type/2 get filtered entries from table" do
    reference = create_table()

    entries =
      [entry_1, entry_2, entry_3, entry_4] =
      [
        create_page_entry(),
        create_page_entry(),
        create_page_entry(locale: :fr),
        create_simple_page_entry()
      ]

    Enum.each(entries, &Table.put(reference, &1))

    page_entries = Table.get_entries_for_content_type(reference, :en, :page)

    assert length(page_entries) == 2
    assert entry_1 in page_entries
    assert entry_2 in page_entries
    assert entry_3 not in page_entries
    assert entry_4 not in page_entries
  end

  test "get_asset/2 get asset from table" do
    reference = create_table()
    asset = create_asset()
    Table.put(reference, asset)
    assert Table.get_asset(reference, asset.id, asset.locale) == asset
  end

  test "delete_asset/2 deletes asset from table" do
    reference = create_table()
    asset_1 = create_asset()
    asset_2 = create_asset()

    Table.put(reference, asset_1)
    Table.put(reference, asset_2)
    Table.delete_asset(reference, asset_1.id, asset_1.locale)

    assert [{_, _, ^asset_2}] = :ets.lookup(reference, {:asset, asset_2.id, asset_2.locale})
    assert [] = :ets.lookup(reference, {:asset, asset_1.id, asset_1.locale})
  end

  defp create_table() do
    Faker.Util.format("%A%4a%A%3a")
    |> String.to_atom()
    |> Table.new()
  end

  defp create_page_entry(opts \\ []) do
    locale = Keyword.get(opts, :locale, :en)

    %Entry{
      store: nil,
      id: Faker.String.base64(10),
      revision: Faker.random_between(1, 1000),
      space_id: "a_space_id",
      content_type: :page,
      fields: %{},
      locale: locale
    }
  end

  defp create_simple_page_entry() do
    %Entry{
      store: nil,
      id: Faker.String.base64(10),
      revision: Faker.random_between(1, 1000),
      space_id: "a_space_id",
      content_type: :simple_page,
      fields: %{},
      locale: :en
    }
  end

  defp create_asset() do
    %Asset{
      store: nil,
      id: Faker.String.base64(10),
      space_id: "a_space_id",
      content_type: "image/jpeg",
      locale: :en,
      title: "An image",
      description: "A cat!!",
      file_name: "cat.jpg",
      url: "https://cdn.cats.com/123",
      width: 10,
      height: 20,
      size: 100
    }
  end
end
