defmodule CFSync.AssetTest do
  use ExUnit.Case, async: true

  doctest CFSync.Asset

  alias CFSync.Asset

  test "new/2 Creates a new asset and correctly maps all values" do
    lang = Faker.String.base64(2)
    id = Faker.String.base64()
    title = Faker.String.base64()
    description = Faker.String.base64()
    content_type = Faker.String.base64()
    file_name = Faker.String.base64()
    url = Faker.String.base64()
    width = Faker.random_between(10, 1000)
    height = Faker.random_between(10, 1000)
    size = Faker.random_between(10, 1000)

    data = %{
      "sys" => %{
        "id" => id,
        "type" => "Asset"
      },
      "fields" => %{
        "title" => %{lang => title},
        "description" => %{lang => description},
        "file" => %{
          lang => %{
            "contentType" => content_type,
            "fileName" => file_name,
            "url" => url,
            "details" => %{
              "image" => %{
                "width" => width,
                "height" => height
              },
              "size" => size
            }
          }
        }
      }
    }

    assert %Asset{
             id: id,
             title: ^title,
             description: ^description,
             content_type: ^content_type,
             file_name: ^file_name,
             url: ^url,
             width: ^width,
             height: ^height,
             size: ^size
           } = Asset.new(data, lang)

    assert id == data["sys"]["id"]
  end
end
