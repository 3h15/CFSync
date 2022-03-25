defmodule CFSync.Store.StateTest do
  use ExUnit.Case, async: true

  doctest CFSync.Store.State

  alias CFSync.Store.State

  test "new/2 creates a State struct with default params" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    s = State.new(name)

    assert %State{
             name: ^name,
             initial_sync_interval: 30,
             delta_sync_interval: 5000
           } = s
  end

  test "new/2 creates a State struct with provided params" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    initial = Faker.random_between(100_000, 200_000)
    delta = Faker.random_between(200_000, 300_000)

    s = State.new(name, initial_sync_interval: initial, delta_sync_interval: delta)

    assert %State{
             name: ^name,
             initial_sync_interval: ^initial,
             delta_sync_interval: ^delta
           } = s
  end

  test "new/2 creates a named ETS table using name param" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    s = State.new(name)

    assert %State{table_reference: ref} = s

    assert ^ref = :ets.whereis(name)
  end

  test "new/2 creates a protected set table, with read concurrency and no write concurrency" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    s = State.new(name)
    info = :ets.info(s.table_reference)

    assert Keyword.fetch!(info, :type) == :set
    assert Keyword.fetch!(info, :protection) == :protected
    assert Keyword.fetch!(info, :read_concurrency) == true
    assert Keyword.fetch!(info, :write_concurrency) == false
  end

  test "update/1 changes next_url" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    s = State.new(name)
    assert s.next_url == nil

    url = Faker.Internet.url()
    s = State.update(s, url)
    assert s.next_url == url
  end
end
