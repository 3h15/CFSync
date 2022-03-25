defmodule CFSync.Store.StateTest do
  use ExUnit.Case, async: true

  doctest CFSync.Store.State

  alias CFSync.Store.State

  test "new/3 creates a State struct with default params" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    reference = make_ref()

    s = State.new(name, reference)

    assert %State{
             name: ^name,
             table_reference: ^reference,
             initial_sync_interval: 30,
             delta_sync_interval: 5000
           } = s
  end

  test "new/3 creates a State struct with provided params" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    reference = make_ref()
    initial = Faker.random_between(100_000, 200_000)
    delta = Faker.random_between(200_000, 300_000)

    s = State.new(name, reference, initial_sync_interval: initial, delta_sync_interval: delta)

    assert %State{
             name: ^name,
             table_reference: ^reference,
             initial_sync_interval: ^initial,
             delta_sync_interval: ^delta
           } = s
  end

  test "update/2 changes next_url" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    reference = make_ref()
    s = State.new(name, reference)

    assert s.next_url == nil

    url = Faker.Internet.url()
    s = State.update(s, url)

    assert %State{
             name: ^name,
             table_reference: ^reference,
             initial_sync_interval: 30,
             delta_sync_interval: 5000,
             next_url: ^url
           } = s
  end
end
