defmodule CFSync.SpaceTest do
  use ExUnit.Case, async: true

  doctest CFSync.Space

  alias CFSync.Space

  test "new/3 creates a valid Space struct" do
    url = Faker.Internet.url()
    space_id = Faker.String.base64(10)
    token = Faker.String.base64(12)

    assert %Space{
             root_url: ^url,
             space_id: ^space_id,
             token: ^token
           } = Space.new(url, space_id, token)
  end
end
