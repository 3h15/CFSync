defmodule CFSync.Store.TableTest do
  use ExUnit.Case, async: true

  doctest CFSync.Store.Table

  alias CFSync.Store.Table

  test "new/1 creates a named ETS table using name param" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    reference = Table.new(name)
    assert :ets.whereis(name) == reference
  end

  test "new/1 creates a protected set table, with read concurrency and no write concurrency" do
    name = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
    reference = Table.new(name)

    info = :ets.info(reference)

    assert Keyword.fetch!(info, :type) == :set
    assert Keyword.fetch!(info, :protection) == :protected
    assert Keyword.fetch!(info, :read_concurrency) == true
    assert Keyword.fetch!(info, :write_concurrency) == false
  end
end
