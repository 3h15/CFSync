defmodule CFSync.Store.StateTest do
  use ExUnit.Case, async: true

  doctest CFSync.Store.State

  alias CFSync.Store.State

  test "new/4 creates a State struct with default params" do
    reference = make_ref()
    s = State.new(My.Name, "a_space_id", "a_delivery_token", %{content_types: nil}, reference)

    assert %State{
             name: My.Name,
             delivery_token: "a_delivery_token",
             content_types: %{content_types: nil},
             locales: %{nil => "en-US"},
             table_reference: ^reference,
             initial_sync_interval: 30,
             delta_sync_interval: 5000,
             next_url: "https://cdn.contentful.com/spaces/a_space_id/sync/?initial=true",
             next_url_type: :next_page,
             auto_tick: true,
             invalidation_callbacks: []
           } = s
  end

  test "new/4 creates a State struct with provided params" do
    reference = make_ref()

    cb = fn -> nil end
    invalidation_callbacks = [cb]

    s =
      State.new(My.Name, "a_space_id", "a_delivery_token", %{content_types: nil}, reference,
        root_url: "https://cfsync.com/",
        locales: %{fr: "fr-FR", de: "de-DE"},
        auto_tick: false,
        initial_sync_interval: 123_456,
        delta_sync_interval: 234_567,
        invalidation_callbacks: invalidation_callbacks
      )

    assert %State{
             name: My.Name,
             delivery_token: "a_delivery_token",
             content_types: %{content_types: nil},
             locales: %{fr: "fr-FR", de: "de-DE"},
             table_reference: ^reference,
             initial_sync_interval: 123_456,
             delta_sync_interval: 234_567,
             next_url: "https://cfsync.com/spaces/a_space_id/sync/?initial=true",
             next_url_type: :next_page,
             auto_tick: false,
             invalidation_callbacks: ^invalidation_callbacks
           } = s
  end

  test "update/3 changes next_url and next_url_type" do
    s = State.new(My.Name, "a_space_id", "a_delivery_token", %{content_types: nil}, make_ref())

    assert s.next_url == "https://cdn.contentful.com/spaces/a_space_id/sync/?initial=true"
    assert s.next_url_type == :next_page

    s = State.update(s, "https://cfsync.com/next_url_path", :next_sync)

    assert %State{
             next_url: "https://cfsync.com/next_url_path",
             next_url_type: :next_sync
           } = s
  end
end
