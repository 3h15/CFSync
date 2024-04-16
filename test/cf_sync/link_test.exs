defmodule CFSync.LinkTest do
  use ExUnit.Case, async: true

  doctest CFSync.Link

  alias CFSync.Link

  test "new/1 Creates a new asset link" do
    data = %{
      "sys" => %{
        "linkType" => "Asset",
        "id" => "ZYXWVU"
      }
    }

    store = make_ref()

    assert %Link{
             store: ^store,
             type: :asset,
             id: "ZYXWVU"
           } = Link.new(data, store)
  end
end
