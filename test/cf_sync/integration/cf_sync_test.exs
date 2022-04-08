defmodule CFSyncTest.Integration.CFSyncTest do
  use ExUnit.Case, async: true

  alias CFSyncTest.FakeHTTPoison
  alias CFSyncTest.FakeHTTPClient
  alias CFSyncTest.Integration.HTTPoisonMock
  alias CFSyncTest.IntegrationTestServer

  import Mox

  import CFSync
  alias CFSync.Entry
  alias CFSync.Asset
  alias CFSync.Link

  test "Integration" do
    # Stub with fake HTTPoison for predefined responses
    stub_with(FakeHTTPoison, HTTPoisonMock)

    # Stub with real modules for integration tests
    stub_with(FakeHTTPClient, CFSync.HTTPClient.HTTPoison)

    space_id = "diw11gmz6opc"
    token = "unC_qLLrGg1iSOK1mHU0IUenA-Ji3deWGjp3H8VRSQA"
    content_types = CFSyncTest.Entries.mapping()

    {:ok, pid} =
      start_link(IntegrationTestServer, space_id, token, content_types, auto_tick: false)

    allow(FakeHTTPoison, self(), pid)
    allow(FakeHTTPClient, self(), pid)

    store = from(IntegrationTestServer)

    assert get_entries(store) == []
    assert get_assets(store) == []

    tick(pid)
    wait_for(fn -> length(get_entries(store)) == 6 end)

    page = get_entry(store, "ygP74CyESVFcDpJojH0tT")
    one = get_asset(store, "5m9oC9bksUxeHqVZXuWk8V")
    altair = get_entry(store, "18vvU4uLfjZA409cWC7BJu")

    assert %Entry{
             content_type: :page,
             fields: %{
               name: "My page",
               boolean: false,
               integer: 7,
               decimal: 7,
               date: ~D[2022-04-15],
               datetime: ~U[2022-03-29 10:14:51.251Z],
               one_asset: %Link{id: "5m9oC9bksUxeHqVZXuWk8V"},
               many_assets: [
                 %Link{id: "NYNi7JZ7Rp2PnbQgjydEV"},
                 %Link{id: "1E2XUWOdWpqDIzAWXZGwtj"},
                 %Link{id: "2pGP9VWr9d2M83TecIJzY0"}
               ],
               one_link: %Link{id: "ygP74CyESVFcDpJojH0tT"},
               many_links: [
                 %Link{id: "18vvU4uLfjZA409cWC7BJu"},
                 %Link{id: "4fy2iBRIRPm20eaViIl0R6"},
                 %Link{id: "FMeGnbv6ZnP6OqSwQSHMW"},
                 %Link{id: "41t5pomHIVxPaeF0fadmG1"},
                 %Link{id: "3hOhfoV5IefhWp2uwq17YW"}
               ]
               #  location: "",
               #  json: "",
             }
           } = page

    assert %Asset{
             title: "One",
             description: "One asset",
             content_type: "image/jpeg",
             file_name: "one.jpg",
             url:
               "//images.ctfassets.net/diw11gmz6opc/5m9oC9bksUxeHqVZXuWk8V/852c68b98e8e5383ade431cb8dbef27f/one.jpg",
             width: 10_235,
             height: 8708,
             size: 6_568_275
           } = one

    assert get_link_target(store, page.fields.one_asset) == one
    assert get_link_target(store, List.first(page.fields.many_links)) == altair

    assert %Entry{fields: %{name: "Altaïr"}} = get_entry(store, "18vvU4uLfjZA409cWC7BJu")
    assert %Entry{fields: %{name: "Tarazed"}} = get_entry(store, "4fy2iBRIRPm20eaViIl0R6")
    assert %Entry{fields: %{name: "Capella"}} = get_entry(store, "FMeGnbv6ZnP6OqSwQSHMW")
    assert %Entry{fields: %{name: "Eltanin"}} = get_entry(store, "41t5pomHIVxPaeF0fadmG1")
    assert %Entry{fields: %{name: "Deneb"}} = get_entry(store, "3hOhfoV5IefhWp2uwq17YW")
    assert %Entry{fields: %{name: "Tarazed"}} = get_entry(store, "4fy2iBRIRPm20eaViIl0R6")

    assert %Asset{title: "Two"} = get_asset(store, "NYNi7JZ7Rp2PnbQgjydEV")
    assert %Asset{title: "Three"} = get_asset(store, "1E2XUWOdWpqDIzAWXZGwtj")
    assert %Asset{title: "Four"} = get_asset(store, "2pGP9VWr9d2M83TecIJzY0")

    tick(pid)
    wait_for(fn -> length(get_entries(store)) == 3 end)

    assert nil == get_entry(store, "4fy2iBRIRPm20eaViIl0R6")
    assert nil == get_entry(store, "3hOhfoV5IefhWp2uwq17YW")
    assert nil == get_entry(store, "FMeGnbv6ZnP6OqSwQSHMW")
    assert nil == get_entry(store, "41t5pomHIVxPaeF0fadmG1")

    assert %Entry{
             fields: %{
               name: "Your page",
               boolean: true,
               integer: 1,
               decimal: 1.2,
               date: nil,
               datetime: nil,
               one_asset: %Link{id: "2pGP9VWr9d2M83TecIJzY0"},
               many_assets: [
                 %Link{id: "2pGP9VWr9d2M83TecIJzY0"},
                 %Link{id: "NYNi7JZ7Rp2PnbQgjydEV"}
               ],
               one_link: %Link{id: "6MQquyPNj1ccczUYRzM7Ky"},
               many_links: [
                 %Link{id: "18vvU4uLfjZA409cWC7BJu"}
               ]
               #  location: "",
               #  json: "",
             }
           } = get_entry(store, "ygP74CyESVFcDpJojH0tT")

    assert %Entry{
             content_type: :star,
             fields: %{name: "Denebola"}
           } = get_entry(store, "6MQquyPNj1ccczUYRzM7Ky")

    tick(pid)
    wait_for(fn -> length(get_entries(store)) == 9 end)

    assert %Entry{
             content_type: :page,
             fields: %{name: "No name"}
           } = get_entry(store, "4MvXPwlHRUiuJyNSI9MXnv")

    assert %Entry{fields: %{name: "Spica"}} = get_entry(store, "13klSU54KfXYbdHKetuEHV")
    assert %Entry{fields: %{name: "Deneb"}} = get_entry(store, "3hOhfoV5IefhWp2uwq17YW")
    assert %Entry{fields: %{name: "Eltanin"}} = get_entry(store, "41t5pomHIVxPaeF0fadmG1")
    assert %Entry{fields: %{name: "Capella"}} = get_entry(store, "FMeGnbv6ZnP6OqSwQSHMW")
    assert %Entry{fields: %{name: "Tarazed"}} = get_entry(store, "4fy2iBRIRPm20eaViIl0R6")

    stars = get_entries_for_content_type(store, :star) |> Enum.sort_by(& &1.fields.name)

    assert [
             %Entry{fields: %{name: "Altaïr"}},
             %Entry{fields: %{name: "Capella"}},
             %Entry{fields: %{name: "Deneb"}},
             %Entry{fields: %{name: "Denebola"}},
             %Entry{fields: %{name: "Eltanin"}},
             %Entry{fields: %{name: "Spica"}},
             %Entry{fields: %{name: "Tarazed"}}
           ] = stars
  end

  defp tick(pid) do
    send(pid, :sync)
  end

  defp wait_for(fun, delay \\ 5, timeout \\ 1000, started_at \\ nil) do
    started_at = started_at || System.monotonic_time(:millisecond)
    elapsed = System.monotonic_time(:millisecond) - started_at
    wait_is_over = fun.()
    timed_out = elapsed >= timeout

    cond do
      wait_is_over ->
        nil

      timed_out ->
        flunk("Timeout!")

      true ->
        Process.sleep(delay)
        wait_for(fun, delay, timeout, started_at)
    end
  end
end
