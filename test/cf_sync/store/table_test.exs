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

  describe "With no locale" do
    test "put/2 inserts entries in table" do
      reference = create_table()
      entry = create_page_entry(locale: nil)
      Table.put(reference, entry)
      assert [{_, _, ^entry}] = :ets.lookup(reference, {:entry, entry.id, nil})
    end

    test "put/2 inserts assets in table" do
      reference = create_table()
      asset = create_asset(locale: nil)
      Table.put(reference, asset)
      assert [{_, _, ^asset}] = :ets.lookup(reference, {:asset, asset.id, nil})
    end

    test "get_entry/2 get entry from table" do
      reference = create_table()
      entry = create_page_entry(locale: nil)
      Table.put(reference, entry)
      assert Table.get_entry(reference, entry.id, nil) == entry
    end

    test "delete_entry/2 deletes entry from table" do
      reference = create_table()
      entry_1 = create_page_entry(locale: nil)
      entry_2 = create_page_entry(locale: nil)
      Table.put(reference, entry_1)
      Table.put(reference, entry_2)
      Table.delete_entry(reference, entry_1.id, nil)

      assert [{_, _, ^entry_2}] = :ets.lookup(reference, {:entry, entry_2.id, nil})
      assert [] = :ets.lookup(reference, {:entry, entry_1.id, nil})
    end

    test "get_entries_for_content_type/2 get filtered entries from table" do
      reference = create_table()

      entries =
        [entry_1, entry_2, entry_3] =
        [
          create_page_entry(locale: nil),
          create_page_entry(locale: nil),
          create_simple_page_entry(locale: nil)
        ]

      Enum.each(entries, &Table.put(reference, &1))

      page_entries = Table.get_entries_for_content_type(reference, nil, :page)

      assert length(page_entries) == 2
      assert entry_1 in page_entries
      assert entry_2 in page_entries
      assert entry_3 not in page_entries
    end

    test "get_asset/2 get asset from table" do
      reference = create_table()
      asset = create_asset(locale: nil)
      Table.put(reference, asset)
      assert Table.get_asset(reference, asset.id, nil) == asset
    end

    test "delete_asset/2 deletes asset from table" do
      reference = create_table()
      asset_1 = create_asset(locale: nil)
      asset_2 = create_asset(locale: nil)

      Table.put(reference, asset_1)
      Table.put(reference, asset_2)
      Table.delete_asset(reference, asset_1.id, nil)

      assert [{_, _, ^asset_2}] = :ets.lookup(reference, {:asset, asset_2.id, nil})
      assert [] = :ets.lookup(reference, {:asset, asset_1.id, nil})
    end

    test "get_link_target/1 returns entry from table" do
      reference = create_table()
      entry = create_page_entry(locale: nil)
      Table.put(reference, entry)
      link = %CFSync.Link{store: reference, type: :entry, id: entry.id, locale: nil}
      assert Table.get_link_target(link) == entry
    end
  end

  describe "With locales" do
    test "put/2 inserts entries in table" do
      reference = create_table()
      entry_fr = create_page_entry(locale: :fr)
      entry_en = create_page_entry(locale: :en)
      Table.put(reference, entry_fr)
      Table.put(reference, entry_en)
      assert [{_, _, ^entry_fr}] = :ets.lookup(reference, {:entry, entry_fr.id, :fr})
      assert [{_, _, ^entry_en}] = :ets.lookup(reference, {:entry, entry_en.id, :en})
    end

    test "put/2 inserts assets in table" do
      reference = create_table()
      asset_de = create_asset(locale: :de)
      asset_it = create_asset(locale: :it)
      Table.put(reference, asset_de)
      Table.put(reference, asset_it)
      assert [{_, _, ^asset_de}] = :ets.lookup(reference, {:asset, asset_de.id, :de})
      assert [{_, _, ^asset_it}] = :ets.lookup(reference, {:asset, asset_it.id, :it})
    end

    test "get_entry/2 get entry from table" do
      reference = create_table()
      entry_pl = create_page_entry(locale: :pl)
      entry_pt = create_page_entry(locale: :pt)
      Table.put(reference, entry_pl)
      Table.put(reference, entry_pt)
      assert Table.get_entry(reference, entry_pl.id, :pl) == entry_pl
      assert Table.get_entry(reference, entry_pt.id, :pt) == entry_pt
    end

    test "delete_entry/2 deletes entry from table" do
      reference = create_table()
      entry_en1 = create_page_entry(locale: :en)
      entry_en2 = create_page_entry(locale: :en)
      entry_es1 = create_page_entry(locale: :es)
      Table.put(reference, entry_en1)
      Table.put(reference, entry_en2)
      Table.put(reference, entry_es1)
      Table.delete_entry(reference, entry_en1.id, :en)

      assert [{_, _, ^entry_en2}] = :ets.lookup(reference, {:entry, entry_en2.id, :en})
      assert [{_, _, ^entry_es1}] = :ets.lookup(reference, {:entry, entry_es1.id, :es})
      assert [] = :ets.lookup(reference, {:entry, entry_en1.id, :en})
    end

    test "get_entries_for_content_type/2 get filtered entries from table" do
      reference = create_table()

      entries =
        [entry_fr1 | [entry_fr2 | _]] =
        [
          create_page_entry(locale: :fr),
          create_page_entry(locale: :fr),
          create_simple_page_entry(locale: :fr),
          create_page_entry(locale: :it),
          create_page_entry(locale: :it),
          create_simple_page_entry(locale: :it)
        ]

      Enum.each(entries, &Table.put(reference, &1))

      fr_page_entries = Table.get_entries_for_content_type(reference, :fr, :page)

      assert length(fr_page_entries) == 2
      assert entry_fr1 in fr_page_entries
      assert entry_fr2 in fr_page_entries
    end

    test "get_asset/2 get asset from table" do
      reference = create_table()
      asset_de = create_asset(locale: :de)
      asset_nl = create_asset(locale: :nl)
      Table.put(reference, asset_de)
      Table.put(reference, asset_nl)
      assert Table.get_asset(reference, asset_de.id, :de) == asset_de
      assert Table.get_asset(reference, asset_nl.id, :nl) == asset_nl
    end

    test "delete_asset/2 deletes asset from table" do
      reference = create_table()
      asset_fr1 = create_asset(locale: :fr)
      asset_fr2 = create_asset(locale: :fr)
      asset_pl1 = create_asset(locale: :pl)

      Table.put(reference, asset_fr1)
      Table.put(reference, asset_fr2)
      Table.put(reference, asset_pl1)

      Table.delete_asset(reference, asset_fr1.id, :fr)

      assert [{_, _, ^asset_fr2}] = :ets.lookup(reference, {:asset, asset_fr2.id, :fr})
      assert [{_, _, ^asset_pl1}] = :ets.lookup(reference, {:asset, asset_pl1.id, :pl})
      assert [] = :ets.lookup(reference, {:asset, asset_fr1.id, :fr})
    end

    test "get_link_target/1 returns entry from table" do
      reference = create_table()
      entry_en = create_page_entry(locale: :en)
      entry_fr = %{entry_en | locale: :fr}
      Table.put(reference, entry_en)
      Table.put(reference, entry_fr)
      link_en = %CFSync.Link{store: reference, type: :entry, id: entry_en.id, locale: :en}
      link_fr = %CFSync.Link{store: reference, type: :entry, id: entry_fr.id, locale: :fr}
      assert Table.get_link_target(link_en) == entry_en
      assert Table.get_link_target(link_fr) == entry_fr
    end
  end

  defp create_table() do
    Faker.Util.format("%A%4a%A%3a")
    |> String.to_atom()
    |> Table.new()
  end

  defp create_page_entry(opts) do
    locale = Keyword.fetch!(opts, :locale)

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

  defp create_simple_page_entry(opts) do
    locale = Keyword.fetch!(opts, :locale)

    %Entry{
      store: nil,
      id: Faker.String.base64(10),
      revision: Faker.random_between(1, 1000),
      space_id: "a_space_id",
      content_type: :simple_page,
      fields: %{},
      locale: locale
    }
  end

  defp create_asset(opts) do
    locale = Keyword.fetch!(opts, :locale)

    %Asset{
      store: nil,
      id: Faker.String.base64(10),
      space_id: "a_space_id",
      content_type: "image/jpeg",
      locale: locale,
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
