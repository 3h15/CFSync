defmodule CFSync.StoreTest do
  use ExUnit.Case, async: true

  doctest CFSync.Store

  import Mox
  import ExUnit.CaptureLog

  alias CFSync.Store

  alias CFSync.Asset
  alias CFSync.Entry

  alias CFSync.Store.Table

  alias CFSyncTest.FakeHTTPClient

  setup :verify_on_exit!

  test "It starts" do
    pid = start_store(auto_tick: false)
    assert is_pid(pid)
    assert Process.alive?(pid)
  end

  test "With auto_tick on, server syncs regularly" do
    parent = self()

    pid = start_store(initial_sync_interval: 10, delta_sync_interval: 10)
    allow(FakeHTTPClient, self(), pid)

    # Step 1, next page
    step_ref_1 = make_ref()

    expect(FakeHTTPClient, :fetch, 1, fn _url, _token ->
      send(parent, {step_ref_1, :temp})
      {:ok, %{"nextPageUrl" => "http://...", "items" => []}}
    end)

    assert_receive {^step_ref_1, :temp}, 15

    # Step 2, next page
    step_ref_2 = make_ref()

    expect(FakeHTTPClient, :fetch, 1, fn _url, _token ->
      send(parent, {step_ref_2, :temp})
      {:ok, %{"nextPageUrl" => "http://...", "items" => []}}
    end)

    assert_receive {^step_ref_2, :temp}, 15

    # Step 3, next sync
    step_ref_3 = make_ref()

    expect(FakeHTTPClient, :fetch, 1, fn _url, _token ->
      send(parent, {step_ref_3, :temp})
      {:ok, %{"nextSyncUrl" => "http://...", "items" => []}}
    end)

    assert_receive {^step_ref_3, :temp}, 15
  end

  test "Server sync pages, then deltas" do
    parent = self()

    next_sync_with = fn expected_url, ref, next_url, next_url_key ->
      expect(FakeHTTPClient, :fetch, fn url, token ->
        assert url == expected_url
        assert token == "a_delivery_token"

        send(parent, {ref, :temp})

        {:ok, %{next_url_key => next_url, "items" => []}}
      end)
    end

    pid = start_store(auto_tick: false)
    allow(FakeHTTPClient, self(), pid)

    step_ref_1 = make_ref()
    url_1 = Faker.Internet.url()

    initial_url = "https://cdn.contentful.com/spaces/a_space_id/sync/?initial=true"
    next_sync_with.(initial_url, step_ref_1, url_1, "nextPageUrl")

    tick(pid)
    assert_receive {^step_ref_1, :temp}

    step_ref_2 = make_ref()
    url_2 = Faker.Internet.url()

    next_sync_with.(url_1, step_ref_2, url_2, "nextSyncUrl")

    tick(pid)
    assert_receive {^step_ref_2, :temp}

    step_ref_3 = make_ref()
    url_3 = Faker.Internet.url()

    next_sync_with.(url_2, step_ref_3, url_3, "nextSyncUrl")

    tick(pid)
    assert_receive {^step_ref_3, :temp}
  end

  test "On sync error, server logs an error and stops" do
    parent = self()

    Process.flag(:trap_exit, true)
    pid = start_store(auto_tick: false)

    step_ref_1 = make_ref()

    expect(FakeHTTPClient, :fetch, fn _url, _token ->
      send(parent, {step_ref_1, :temp})
      {:error, :any_message}
    end)

    allow(FakeHTTPClient, self(), pid)

    {_result, log} =
      with_log(
        [level: :error],
        fn ->
          tick(pid)
          assert_receive {^step_ref_1, :temp}
          assert_receive({:EXIT, ^pid, _})
        end
      )

    assert log =~ "Sync request error, exiting."
    refute Process.alive?(pid)
  end

  test "When rate limited, server stays alive" do
    parent = self()

    Process.flag(:trap_exit, true)
    pid = start_store(auto_tick: false)

    step_ref_1 = make_ref()

    expect(FakeHTTPClient, :fetch, fn _url, _token ->
      send(parent, {step_ref_1, :temp})
      {:rate_limited, Faker.random_between(1, 100)}
    end)

    allow(FakeHTTPClient, self(), pid)

    tick(pid)
    assert_receive {^step_ref_1, :temp}
    refute_receive({:EXIT, ^pid, _}, 250)
    assert Process.alive?(pid)
  end

  test "Server adds and remove entries and assets from multiple locales" do
    parent = self()

    item = fn
      Asset, id, type ->
        %{
          "sys" => %{"id" => id, "type" => type, "space" => %{"sys" => %{"id" => "anyspace"}}},
          "fields" => %{
            "title" => %{},
            "description" => %{},
            "file" => %{
              "en_US" => %{
                "contentType" => "",
                "fileName" => "",
                "url" => "",
                "details" => %{
                  "image" => %{
                    "width" => 0,
                    "height" => 0
                  },
                  "size" => 0
                }
              }
            }
          }
        }

      Entry, id, type ->
        %{
          "sys" => %{
            "id" => id,
            "type" => type,
            "revision" => 1,
            "contentType" => %{"sys" => %{"id" => "page"}},
            "space" => %{"sys" => %{"id" => "anyspace"}}
          },
          "fields" => %{}
        }
    end

    pid = start_store(auto_tick: false, locales: %{en: "en_US", fr: "fr_FR"})
    allow(FakeHTTPClient, self(), pid)

    sync_with = fn items ->
      ref = make_ref()

      expect(FakeHTTPClient, :fetch, fn _url, _token ->
        send(parent, {ref, :temp})
        {:ok, %{"nextSyncUrl" => "", "items" => items}}
      end)

      tick(pid)
      assert_receive {^ref, :temp}

      # Wait for an empty sync cycle to ensure :ets is synced
      # Without this, the test tries to get records from the table before
      # they're inserted
      ref = make_ref()

      expect(FakeHTTPClient, :fetch, fn _url, _token ->
        send(parent, {ref, :temp})
        {:ok, %{"nextSyncUrl" => "", "items" => []}}
      end)

      tick(pid)
      assert_receive {^ref, :temp}
    end

    # Add some items
    sync_with.([
      item.(Entry, "1-upsert-entry", "Entry"),
      item.(Entry, "2-upsert-entry", "Entry"),
      item.(Asset, "3-upsert-asset", "Asset"),
      item.(Asset, "4-upsert-asset", "Asset")
    ])

    table_ref = Table.get_table_reference_for_name(__MODULE__.TestServer)

    assert [
             %Entry{store: ^table_ref, id: "1-upsert-entry", locale: :en},
             %Entry{store: ^table_ref, id: "2-upsert-entry", locale: :en}
           ] = Table.get_entries(table_ref, :en) |> Enum.sort_by(& &1.id)

    assert [
             %Entry{store: ^table_ref, id: "1-upsert-entry", locale: :fr},
             %Entry{store: ^table_ref, id: "2-upsert-entry", locale: :fr}
           ] = Table.get_entries(table_ref, :fr) |> Enum.sort_by(& &1.id)

    assert [
             %Asset{store: ^table_ref, id: "3-upsert-asset", locale: :en},
             %Asset{store: ^table_ref, id: "4-upsert-asset", locale: :en}
           ] = Table.get_assets(table_ref, :en) |> Enum.sort_by(& &1.id)

    assert [
             %Asset{store: ^table_ref, id: "3-upsert-asset", locale: :fr},
             %Asset{store: ^table_ref, id: "4-upsert-asset", locale: :fr}
           ] = Table.get_assets(table_ref, :fr) |> Enum.sort_by(& &1.id)

    #  Add some items should concat with previsou
    sync_with.([
      item.(Asset, "5-upsert-asset", "Asset"),
      item.(Asset, "6-upsert-asset", "Asset"),
      item.(Entry, "7-upsert-entry", "Entry"),
      item.(Entry, "8-upsert-entry", "Entry")
    ])

    assert [
             %Entry{id: "1-upsert-entry"},
             %Entry{id: "2-upsert-entry"},
             %Entry{id: "7-upsert-entry"},
             %Entry{id: "8-upsert-entry"}
           ] = Table.get_entries(table_ref, :en) |> Enum.sort_by(& &1.id)

    assert [
             %Asset{id: "3-upsert-asset"},
             %Asset{id: "4-upsert-asset"},
             %Asset{id: "5-upsert-asset"},
             %Asset{id: "6-upsert-asset"}
           ] = Table.get_assets(table_ref, :en) |> Enum.sort_by(& &1.id)

    #  Delete some items should keep other ones
    sync_with.([
      item.(Asset, "4-upsert-asset", "DeletedAsset"),
      item.(Asset, "5-upsert-asset", "DeletedAsset"),
      item.(Entry, "1-upsert-entry", "DeletedEntry"),
      item.(Entry, "8-upsert-entry", "DeletedEntry")
    ])

    assert [
             %Entry{id: "2-upsert-entry"},
             %Entry{id: "7-upsert-entry"}
           ] = Table.get_entries(table_ref, :en) |> Enum.sort_by(& &1.id)

    assert [
             %Asset{id: "3-upsert-asset"},
             %Asset{id: "6-upsert-asset"}
           ] = Table.get_assets(table_ref, :en) |> Enum.sort_by(& &1.id)

    #  Delete remaining items to ensure we can empty the tables without crashing
    sync_with.([
      item.(Asset, "3-upsert-asset", "DeletedAsset"),
      item.(Asset, "6-upsert-asset", "DeletedAsset"),
      item.(Entry, "2-upsert-entry", "DeletedEntry"),
      item.(Entry, "7-upsert-entry", "DeletedEntry")
    ])

    assert [] = Table.get_entries(table_ref, :en) |> Enum.sort_by(& &1.id)
    assert [] = Table.get_assets(table_ref, :en) |> Enum.sort_by(& &1.id)

    assert [] = Table.get_entries(table_ref, :fr) |> Enum.sort_by(& &1.id)
    assert [] = Table.get_assets(table_ref, :fr) |> Enum.sort_by(& &1.id)

    #  Delete inexistent items should not crash
    sync_with.([
      item.(Asset, "3-upsert-asset", "DeletedAsset"),
      item.(Asset, "6-upsert-asset", "DeletedAsset"),
      item.(Entry, "2-upsert-entry", "DeletedEntry"),
      item.(Entry, "7-upsert-entry", "DeletedEntry")
    ])

    assert [] = Table.get_entries(table_ref, :en) |> Enum.sort_by(& &1.id)
    assert [] = Table.get_assets(table_ref, :en) |> Enum.sort_by(& &1.id)

    assert [] = Table.get_entries(table_ref, :fr) |> Enum.sort_by(& &1.id)
    assert [] = Table.get_assets(table_ref, :fr) |> Enum.sort_by(& &1.id)

    # The server should still be in a state where is accepts new items
    sync_with.([
      item.(Entry, "1-upsert-entry", "Entry"),
      item.(Entry, "2-upsert-entry", "Entry"),
      item.(Asset, "3-upsert-asset", "Asset"),
      item.(Asset, "4-upsert-asset", "Asset")
    ])

    assert [
             %Entry{id: "1-upsert-entry"},
             %Entry{id: "2-upsert-entry"}
           ] = Table.get_entries(table_ref, :en) |> Enum.sort_by(& &1.id)

    assert [
             %Asset{id: "3-upsert-asset"},
             %Asset{id: "4-upsert-asset"}
           ] = Table.get_assets(table_ref, :en) |> Enum.sort_by(& &1.id)

    assert [
             %Entry{id: "1-upsert-entry"},
             %Entry{id: "2-upsert-entry"}
           ] = Table.get_entries(table_ref, :fr) |> Enum.sort_by(& &1.id)

    assert [
             %Asset{id: "3-upsert-asset"},
             %Asset{id: "4-upsert-asset"}
           ] = Table.get_assets(table_ref, :fr) |> Enum.sort_by(& &1.id)
  end

  test "Server calls invalidation callbacks when needed" do
    parent = self()

    item = fn
      Asset, id, type ->
        %{
          "sys" => %{"id" => id, "type" => type, "space" => %{"sys" => %{"id" => "anyspace"}}},
          "fields" => %{
            "title" => %{"en_US" => ""},
            "description" => %{"en_US" => ""},
            "file" => %{
              "en_US" => %{
                "contentType" => "",
                "fileName" => "",
                "url" => "",
                "details" => %{
                  "image" => %{
                    "width" => 0,
                    "height" => 0
                  },
                  "size" => 0
                }
              }
            }
          }
        }

      Entry, id, type ->
        %{
          "sys" => %{
            "id" => id,
            "type" => type,
            "revision" => 1,
            "contentType" => %{"sys" => %{"id" => "page"}},
            "space" => %{"sys" => %{"id" => "anyspace"}}
          },
          "fields" => %{}
        }
    end

    invalidate_ref = make_ref()

    invalidate = fn ->
      send(parent, {invalidate_ref, :invalidation})
    end

    pid = start_store(auto_tick: false, invalidation_callbacks: [invalidate])
    allow(FakeHTTPClient, self(), pid)

    sync_with = fn items ->
      ref = make_ref()

      expect(FakeHTTPClient, :fetch, fn _url, _token ->
        send(parent, {ref, :temp})
        {:ok, %{"nextSyncUrl" => "", "items" => items}}
      end)

      tick(pid)
      assert_receive {^ref, :temp}
    end

    # Add some items
    sync_with.([item.(Entry, "1-upsert-entry", "Entry")])
    assert_receive {^invalidate_ref, :invalidation}

    #  Add some items should concat with previsou
    sync_with.([])
    refute_receive {^invalidate_ref, :invalidation}
  end

  test "Server correctly handles force_sync" do
    parent = self()

    next_sync_with = fn expected_url, ref, next_url, next_url_key ->
      expect(FakeHTTPClient, :fetch, fn url, token ->
        assert url == expected_url
        assert token == "a_delivery_token"

        send(parent, {ref, :temp})

        {:ok, %{next_url_key => next_url, "items" => []}}
      end)
    end

    pid = start_store(initial_sync_interval: 10, delta_sync_interval: 10)
    allow(FakeHTTPClient, self(), pid)

    # Step 1, next sync
    step_ref_1 = make_ref()
    url_1 = Faker.Internet.url()

    initial_url = "https://cdn.contentful.com/spaces/a_space_id/sync/?initial=true"
    next_sync_with.(initial_url, step_ref_1, url_1, "nextSyncUrl")

    assert_receive {^step_ref_1, :temp}, 15

    # Step 2, force sync
    step_ref_2 = make_ref()
    url_2 = Faker.Internet.url()

    next_sync_with.(url_1, step_ref_2, url_2, "nextSyncUrl")
    Store.force_sync(__MODULE__.TestServer)
    assert_receive {^step_ref_2, :temp}, 2

    # Step 3, next sync
    step_ref_3 = make_ref()
    url_3 = Faker.Internet.url()
    next_sync_with.(url_2, step_ref_3, url_3, "nextSyncUrl")

    refute_receive {^step_ref_3, :temp}, 7
    assert_receive {^step_ref_3, :temp}, 4
  end

  defp start_store(opts) do
    opts =
      Keyword.merge(
        [
          name: __MODULE__.TestServer,
          space_id: "a_space_id",
          delivery_token: "a_delivery_token",
          content_types: CFSyncTest.Entries.mapping()
        ],
        opts
      )

    start_link_supervised!({Store, opts})
  end

  defp tick(pid) do
    send(pid, :sync)
  end
end
