defmodule CFSync.SyncConnectorTest do
  use ExUnit.Case, async: true

  doctest CFSync.SyncConnector

  import Mox

  alias CFSync.FakeHTTPClient
  alias CFSync.SyncConnector
  alias CFSync.Space

  setup :verify_on_exit!

  setup do
    root_url = Faker.Internet.url()
    space_id = Faker.String.base64(10)
    token = Faker.String.base64(12)

    lang = Faker.String.base64(2)

    space = Space.new(root_url, space_id, token)
    %{lang: lang, space: space}
  end

  test "It fetches initial URL when called with url = nil", %{lang: lang, space: space} do
    expect(FakeHTTPClient, :fetch, 1, fn url, token ->
      assert token == space.token
      expected_url = space.root_url <> "spaces/" <> space.space_id <> "/sync/?initial=true"
      assert expected_url == url
      {:ok, %{"nextPageUrl" => "", "items" => []}}
    end)

    SyncConnector.sync(space, lang)
  end

  test "It fetches provided URL when called with an url", %{lang: lang, space: space} do
    provided_url = Faker.Internet.url()

    expect(FakeHTTPClient, :fetch, 1, fn url, token ->
      assert token == space.token
      assert ^provided_url = url
      {:ok, %{"nextPageUrl" => "", "items" => []}}
    end)

    SyncConnector.sync(space, lang, provided_url)
  end

  test "It returns rate limit as is.", %{lang: lang, space: space} do
    rate_limit = {:rate_limited, Faker.random_between(1, 1000)}

    expect(FakeHTTPClient, :fetch, 1, fn _url, _token ->
      rate_limit
    end)

    assert ^rate_limit = SyncConnector.sync(space, lang)
  end

  test "It returns error ass is.", %{lang: lang, space: space} do
    error = {:error, Faker.String.base64(12)}

    expect(FakeHTTPClient, :fetch, 1, fn _url, _token ->
      error
    end)

    assert ^error = SyncConnector.sync(space, lang)
  end
end
