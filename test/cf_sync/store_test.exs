defmodule CFSync.StoreTest do
  use ExUnit.Case, async: true

  doctest CFSync.Store

  import Mox
  import ExUnit.CaptureLog

  alias CFSync.Store
  alias CFSync.Space
  alias CFSync.SyncPayload

  alias CFSync.Asset
  alias CFSync.Entry

  alias CFSync.Store.Table

  alias CFSyncTest.FakeSyncConnector

  setup :verify_on_exit!

  setup do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    space = Space.new(Faker.Internet.url(), Faker.String.base64(), Faker.String.base64())
    locale = Faker.String.base64(2)

    start_server = fn opts ->
      name = Keyword.get(opts, :name, name)
      opts = opts ++ [space: space, locale: locale]
      opts = Enum.uniq_by(opts, fn {k, _v} -> k end)
      {:ok, pid} = Store.start_link(name, opts)

      tick = fn ->
        send(pid, :sync)
      end

      {pid, tick}
    end

    %{name: name, space: space, locale: locale, start_server: start_server}
  end

  test "start_link/2 starts the server", %{start_server: start_server} do
    {pid, _tick} = start_server.(auto_tick: false)
    assert is_pid(pid)
    assert Process.alive?(pid)
  end

  test "With auto_tick on, server syncs regularly", %{start_server: start_server} do
    parent = self()

    {pid, _tick} = start_server.(initial_sync_interval: 10, delta_sync_interval: 10)
    allow(FakeSyncConnector, self(), pid)

    # Step 1, return :next_page
    step_ref_1 = make_ref()

    expect(FakeSyncConnector, :sync, 1, fn _sp, _locale, _url ->
      send(parent, {step_ref_1, :temp})
      {:ok, %SyncPayload{next_url: "http://...", next_url_type: :next_page, deltas: []}}
    end)

    assert_receive {^step_ref_1, :temp}, 15

    # Step 2, return :next_page
    step_ref_2 = make_ref()

    expect(FakeSyncConnector, :sync, 1, fn _sp, _locale, _url ->
      send(parent, {step_ref_2, :temp})
      {:ok, %SyncPayload{next_url: "http://...", next_url_type: :next_page, deltas: []}}
    end)

    assert_receive {^step_ref_2, :temp}, 15

    # Step 3, return :next_sync
    step_ref_3 = make_ref()

    expect(FakeSyncConnector, :sync, 1, fn _sp, _locale, _url ->
      send(parent, {step_ref_3, :temp})
      {:ok, %SyncPayload{next_url: "http://...", next_url_type: :next_sync, deltas: []}}
    end)

    assert_receive {^step_ref_3, :temp}, 15
  end

  test "Server sync pages, then deltas", %{space: space, start_server: start_server} do
    parent = self()

    next_sync_with = fn expected_url, ref, next_url, next_url_type ->
      expect(FakeSyncConnector, :sync, fn sp, _locale, url ->
        assert sp == space
        assert url == expected_url

        send(parent, {ref, :temp})
        {:ok, %SyncPayload{next_url: next_url, next_url_type: next_url_type, deltas: []}}
      end)
    end

    {pid, tick} = start_server.(auto_tick: false)
    allow(FakeSyncConnector, self(), pid)

    step_ref_1 = make_ref()
    url_1 = Faker.Internet.url()

    next_sync_with.(nil, step_ref_1, url_1, :next_page)

    tick.()
    assert_receive {^step_ref_1, :temp}

    step_ref_2 = make_ref()
    url_2 = Faker.Internet.url()

    next_sync_with.(url_1, step_ref_2, url_2, :next_page)

    tick.()
    assert_receive {^step_ref_2, :temp}

    step_ref_3 = make_ref()
    url_3 = Faker.Internet.url()

    next_sync_with.(url_2, step_ref_3, url_3, :next_sync)

    tick.()
    assert_receive {^step_ref_3, :temp}
  end

  test "On sync error, server logs an error and stops", %{
    start_server: start_server
  } do
    parent = self()

    Process.flag(:trap_exit, true)
    {pid, tick} = start_server.(auto_tick: false)

    step_ref_1 = make_ref()

    expect(FakeSyncConnector, :sync, fn _space, _locale, _url ->
      send(parent, {step_ref_1, :temp})
      {:error, :any_message}
    end)

    allow(FakeSyncConnector, self(), pid)

    {_result, log} =
      with_log(
        [level: :error],
        fn ->
          tick.()
          assert_receive {^step_ref_1, :temp}
          assert_receive({:EXIT, ^pid, _})
        end
      )

    assert log =~ "Sync request error, exiting."
    refute Process.alive?(pid)
  end

  test "When rate limited, server stays alive", %{
    start_server: start_server
  } do
    parent = self()

    Process.flag(:trap_exit, true)
    {pid, tick} = start_server.(auto_tick: false)

    step_ref_1 = make_ref()

    expect(FakeSyncConnector, :sync, fn _space, _locale, _url ->
      send(parent, {step_ref_1, :temp})
      {:rate_limited, Faker.random_between(1, 100)}
    end)

    allow(FakeSyncConnector, self(), pid)

    tick.()
    assert_receive {^step_ref_1, :temp}
    refute_receive({:EXIT, ^pid, _}, 250)

    assert Process.alive?(pid)
  end

  test "Server adds and remove entries and assets", %{
    name: name,
    locale: locale,
    start_server: start_server
  } do
    parent = self()

    item = fn
      Asset, id, type ->
        %{
          "sys" => %{"id" => id, "type" => type},
          "fields" => %{
            "title" => %{locale => ""},
            "description" => %{locale => ""},
            "file" => %{
              locale => %{
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
            "contentType" => %{"sys" => %{"id" => "page"}}
          },
          "fields" => %{}
        }
    end

    {pid, tick} = start_server.(auto_tick: false)
    allow(FakeSyncConnector, self(), pid)

    sync_with = fn items ->
      ref = make_ref()

      expect(FakeSyncConnector, :sync, fn _space, _locale, _url ->
        send(parent, {ref, :temp})
        {:ok, SyncPayload.new(%{"nextSyncUrl" => "", "items" => items}, locale)}
      end)

      tick.()
      assert_receive {^ref, :temp}

      # Wait for an empty sync cycle to ensure :ets is synced
      # Without this, the test tries to get records from the table before
      # they're inserted
      ref = make_ref()

      expect(FakeSyncConnector, :sync, fn _space, _locale, _url ->
        send(parent, {ref, :temp})
        {:ok, SyncPayload.new(%{"nextSyncUrl" => "", "items" => []}, locale)}
      end)

      tick.()
      assert_receive {^ref, :temp}
    end

    # Add some items
    sync_with.([
      item.(Entry, "1-upsert-entry", "Entry"),
      item.(Entry, "2-upsert-entry", "Entry"),
      item.(Asset, "3-upsert-asset", "Asset"),
      item.(Asset, "4-upsert-asset", "Asset")
    ])

    assert [
             %Entry{id: "1-upsert-entry"},
             %Entry{id: "2-upsert-entry"}
           ] = Table.get_entries(name) |> Enum.sort_by(& &1.id)

    assert [
             %Asset{id: "3-upsert-asset"},
             %Asset{id: "4-upsert-asset"}
           ] = Table.get_assets(name) |> Enum.sort_by(& &1.id)

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
           ] = Table.get_entries(name) |> Enum.sort_by(& &1.id)

    assert [
             %Asset{id: "3-upsert-asset"},
             %Asset{id: "4-upsert-asset"},
             %Asset{id: "5-upsert-asset"},
             %Asset{id: "6-upsert-asset"}
           ] = Table.get_assets(name) |> Enum.sort_by(& &1.id)

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
           ] = Table.get_entries(name) |> Enum.sort_by(& &1.id)

    assert [
             %Asset{id: "3-upsert-asset"},
             %Asset{id: "6-upsert-asset"}
           ] = Table.get_assets(name) |> Enum.sort_by(& &1.id)

    #  Delete remaining items to ensure we can empty the tables without crashing
    sync_with.([
      item.(Asset, "3-upsert-asset", "DeletedAsset"),
      item.(Asset, "6-upsert-asset", "DeletedAsset"),
      item.(Entry, "2-upsert-entry", "DeletedEntry"),
      item.(Entry, "7-upsert-entry", "DeletedEntry")
    ])

    assert [] = Table.get_entries(name) |> Enum.sort_by(& &1.id)

    assert [] = Table.get_assets(name) |> Enum.sort_by(& &1.id)

    #  Delete inexistent items should not crash
    sync_with.([
      item.(Asset, "3-upsert-asset", "DeletedAsset"),
      item.(Asset, "6-upsert-asset", "DeletedAsset"),
      item.(Entry, "2-upsert-entry", "DeletedEntry"),
      item.(Entry, "7-upsert-entry", "DeletedEntry")
    ])

    assert [] = Table.get_entries(name) |> Enum.sort_by(& &1.id)

    assert [] = Table.get_assets(name) |> Enum.sort_by(& &1.id)

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
           ] = Table.get_entries(name) |> Enum.sort_by(& &1.id)

    assert [
             %Asset{id: "3-upsert-asset"},
             %Asset{id: "4-upsert-asset"}
           ] = Table.get_assets(name) |> Enum.sort_by(& &1.id)
  end
end
