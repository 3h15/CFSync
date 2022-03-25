defmodule CFSync.Store.StateTest do
  use ExUnit.Case, async: true

  doctest CFSync.Store.State

  alias CFSync.Store.State
  alias CFSync.Space

  setup do
    %{
      name: Faker.Util.format("%A%4a%A%3a") |> String.to_atom(),
      space: Space.new(Faker.Internet.url(), Faker.String.base64(), Faker.String.base64()),
      locale: Faker.String.base64(2),
      reference: make_ref()
    }
  end

  test "new/3 creates a State struct with default params", %{
    name: name,
    space: space,
    locale: locale,
    reference: reference
  } do
    s = State.new(name, space, locale, reference)

    assert %State{
             name: ^name,
             space: ^space,
             locale: ^locale,
             table_reference: ^reference,
             initial_sync_interval: 30,
             delta_sync_interval: 5000
           } = s
  end

  test "new/3 creates a State struct with provided params", %{
    name: name,
    space: space,
    locale: locale,
    reference: reference
  } do
    initial = Faker.random_between(100_000, 200_000)
    delta = Faker.random_between(200_000, 300_000)

    s =
      State.new(name, space, locale, reference,
        initial_sync_interval: initial,
        delta_sync_interval: delta
      )

    assert %State{
             name: ^name,
             space: ^space,
             locale: ^locale,
             table_reference: ^reference,
             initial_sync_interval: ^initial,
             delta_sync_interval: ^delta
           } = s
  end

  test "update/3 changes next_url and next_url_type", %{
    name: name,
    space: space,
    locale: locale,
    reference: reference
  } do
    s = State.new(name, space, locale, reference)

    assert s.next_url == nil
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

  test "By default, auto_tick is true", %{
    name: name,
    space: space,
    locale: locale,
    reference: reference
  } do
    s = State.new(name, space, locale, reference)

    assert s.auto_tick == true
  end

  test "auto_tick can be set to false", %{
    name: name,
    space: space,
    locale: locale,
    reference: reference
  } do
    s = State.new(name, space, locale, reference, auto_tick: false)

    assert s.auto_tick == false
  end
end
