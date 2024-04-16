defmodule CFSync.AssetTest do
  use ExUnit.Case, async: true

  doctest CFSync.Asset

  alias CFSync.Asset

  test "new/2 Creates a new asset and correctly maps all values" do
    data = %{
      "sys" => %{
        "id" => "ABCDEF",
        "type" => "Asset",
        "space" => %{
          "sys" => %{
            "id" => "GHIJKL"
          }
        }
      },
      "fields" => %{
        "title" => %{"en_US" => "A cat!"},
        "description" => %{"en_US" => "A picture of a cat"},
        "file" => %{
          "en_US" => %{
            "contentType" => "image/jpeg",
            "fileName" => "cat.jpg",
            "url" => "https://example.com/cat.jpg",
            "details" => %{
              "image" => %{
                "width" => 123,
                "height" => 456
              },
              "size" => 789
            }
          }
        }
      }
    }

    store = make_ref()

    assert %Asset{
             store: ^store,
             space_id: "GHIJKL",
             id: "ABCDEF",
             locale: :en,
             title: "A cat!",
             description: "A picture of a cat",
             content_type: "image/jpeg",
             file_name: "cat.jpg",
             url: "https://example.com/cat.jpg",
             width: 123,
             height: 456,
             size: 789
           } = Asset.new(data, {:en, "en_US"}, store)
  end
end
