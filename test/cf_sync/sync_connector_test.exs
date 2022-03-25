defmodule CFSync.SyncConnectorTest do
  use ExUnit.Case, async: true

  doctest CFSync.SyncConnector

  import Mox

  alias CFSync.FakeHTTPClient
  alias CFSync.SyncConnector
  alias CFSync.Space

  setup :verify_on_exit!

  test "It fetches initial URL when called with url = nil" do
    root_url = Faker.Internet.url()
    space_id = Faker.String.base64(10)
    token = Faker.String.base64(12)

    space = Space.new(root_url, space_id, token)

    expect(FakeHTTPClient, :fetch, 1, fn url, token ->
      assert token == space.token
      expected_url = root_url <> "spaces/" <> space_id <> "/sync/?initial=true"
      assert expected_url == url
    end)

    SyncConnector.sync(space)
  end

  test "It fetches provided URL when called with an url" do
    root_url = Faker.Internet.url()
    space_id = Faker.String.base64(10)
    token = Faker.String.base64(12)

    provided_url = Faker.Internet.url()

    space = Space.new(root_url, space_id, token)

    expect(FakeHTTPClient, :fetch, 1, fn url, token ->
      assert token == space.token
      assert ^provided_url = url
    end)

    SyncConnector.sync(space, provided_url)
  end
end
