defmodule CFSync.StoreTest do
  use ExUnit.Case, async: true

  doctest CFSync.Store

  import Mox
  import ExUnit.CaptureLog

  alias CFSync.Store
  alias CFSync.Space
  alias CFSync.SyncPayload

  alias CFSync.FakeSyncConnector

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
end
