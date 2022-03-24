defmodule CFSync.LinkTest do
  use ExUnit.Case, async: true

  doctest CFSync.Link

  alias CFSync.Link

  test "new/1 Creates a new asset link" do
    target_id = Faker.String.base64()

    data = %{
      "sys" => %{
        "linkType" => "Asset",
        "id" => target_id
      }
    }

    assert %Link{
             type: :asset,
             id: ^target_id
           } = Link.new(data)
  end
end
