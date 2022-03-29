defmodule CFSync.HTTPClient.HTTPoisonTest do
  use ExUnit.Case, async: true

  doctest CFSync.HTTPClient.HTTPoison

  import ExUnit.CaptureLog
  import Mox

  alias CFSync.FakeHTTPoison
  alias CFSync.HTTPClient

  setup :verify_on_exit!

  test "It calls request function with correct data" do
    url = Faker.Internet.url()
    token = Faker.String.base64(12)

    expect(FakeHTTPoison, :request, 1, fn req ->
      assert %{
               method: :get,
               headers: [
                 {"Content-Type", "application/json"},
                 {"authorization", "Bearer " <> ^token}
               ],
               options: [ssl: [{:versions, [:"tlsv1.2"]}]],
               url: ^url
             } = req

      {:ok, %{status_code: 200, body: "[]"}}
    end)

    HTTPClient.HTTPoison.fetch(url, token)
  end

  test "It handles known errors codes" do
    known_codes = [
      {401, :unauthorized, "Unauthorized request"},
      {422, :unprocessable, "Unprocessable Entity"}
    ]

    for {code, atom, msg} <- known_codes do
      expect(FakeHTTPoison, :request, 1, fn _req ->
        {:ok, %{status_code: code}}
      end)

      {result, log} =
        with_log(
          [level: :error],
          fn ->
            HTTPClient.HTTPoison.fetch("url", "token")
          end
        )

      assert {:error, ^atom} = result
      assert log =~ "Contentful request failed: #{msg}"
    end
  end

  test "It handles unknown errors codes" do
    code = Faker.random_between(10_000, 99_000)

    expect(FakeHTTPoison, :request, 1, fn _req ->
      {:ok, %{status_code: code}}
    end)

    {result, log} =
      with_log(
        [level: :error],
        fn ->
          HTTPClient.HTTPoison.fetch("url", "token")
        end
      )

    assert {:error, :unknown} = result
    assert log =~ "Unhandled Contentful status code: #{code}"
  end

  test "It handles rate limiting" do
    delay = Faker.random_between(1, 100)

    expect(FakeHTTPoison, :request, 1, fn _req ->
      {:ok,
       %{
         status_code: 429,
         headers: [{"X-Contentful-RateLimit-Reset", Integer.to_string(delay)}]
       }}
    end)

    {result, log} =
      with_log(
        [level: :error],
        fn ->
          HTTPClient.HTTPoison.fetch("url", "token")
        end
      )

    assert {:rate_limited, ^delay} = result
    assert log =~ "Contentful request failed: Rate limited"
  end

  test "It handles rate limiting with defautl delay if none is provided in headers" do
    expect(FakeHTTPoison, :request, 1, fn _req ->
      {:ok,
       %{
         status_code: 429,
         headers: []
       }}
    end)

    {result, log} =
      with_log(
        [level: :error],
        fn ->
          HTTPClient.HTTPoison.fetch("url", "token")
        end
      )

    assert {:rate_limited, 10} = result
    assert log =~ "Contentful request failed: Rate limited"
  end

  test "It handles response and decodes JSON" do
    data = %{"content" => Faker.Lorem.paragraph()}

    expect(FakeHTTPoison, :request, 1, fn _req ->
      {:ok,
       %{
         status_code: 200,
         body: Jason.encode!(data)
       }}
    end)

    assert {:ok, ^data} = HTTPClient.HTTPoison.fetch("url", "token")
  end
end
