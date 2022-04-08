defmodule CFSync.Store.StateTest do
  use ExUnit.Case, async: true

  doctest CFSync.Store.State

  alias CFSync.Store.State

  setup do
    %{
      name: Faker.Util.format("%A%4a%A%3a") |> String.to_atom(),
      space_id: Faker.String.base64(),
      delivery_token: Faker.String.base64(),
      content_types: CFSyncTest.Entries.mapping(),
      reference: make_ref()
    }
  end

  test "new/4 creates a State struct with default params", %{
    name: name,
    space_id: space_id,
    delivery_token: delivery_token,
    content_types: content_types,
    reference: reference
  } do
    s = State.new(name, space_id, delivery_token, content_types, reference)

    expected_url = "https://cdn.contentful.com/spaces/" <> space_id <> "/sync/?initial=true"

    assert %State{
             name: ^name,
             delivery_token: ^delivery_token,
             content_types: ^content_types,
             locale: "en-US",
             table_reference: ^reference,
             initial_sync_interval: 30,
             delta_sync_interval: 5000,
             next_url: ^expected_url,
             next_url_type: :next_page,
             auto_tick: true,
             invalidation_callbacks: []
           } = s
  end

  test "new/4 creates a State struct with provided params", %{
    name: name,
    space_id: space_id,
    delivery_token: delivery_token,
    content_types: content_types,
    reference: reference
  } do
    root_url = Faker.Internet.url()
    locale = Faker.String.base64(2)
    initial = Faker.random_between(100_000, 200_000)
    delta = Faker.random_between(200_000, 300_000)

    expected_url = root_url <> "spaces/" <> space_id <> "/sync/?initial=true"

    cb = fn -> nil end
    invalidation_callbacks = [cb]

    s =
      State.new(name, space_id, delivery_token, content_types, reference,
        root_url: root_url,
        content_types: content_types,
        locale: locale,
        auto_tick: false,
        initial_sync_interval: initial,
        delta_sync_interval: delta,
        invalidation_callbacks: invalidation_callbacks
      )

    assert %State{
             name: ^name,
             delivery_token: ^delivery_token,
             content_types: ^content_types,
             locale: ^locale,
             table_reference: ^reference,
             initial_sync_interval: ^initial,
             delta_sync_interval: ^delta,
             next_url: ^expected_url,
             next_url_type: :next_page,
             auto_tick: false,
             invalidation_callbacks: ^invalidation_callbacks
           } = s
  end

  test "update/3 changes next_url and next_url_type", %{
    name: name,
    space_id: space_id,
    delivery_token: delivery_token,
    content_types: content_types,
    reference: reference
  } do
    s = State.new(name, space_id, delivery_token, content_types, reference)

    assert s.next_url == "https://cdn.contentful.com/spaces/" <> space_id <> "/sync/?initial=true"
    assert s.next_url_type == :next_page

    url = Faker.Internet.url()
    s = State.update(s, url, :next_sync)

    assert %State{
             name: ^name,
             table_reference: ^reference,
             initial_sync_interval: 30,
             delta_sync_interval: 5000,
             next_url: ^url,
             next_url_type: :next_sync
           } = s
  end
end
