defmodule CFSync.SyncAPITest do
  use ExUnit.Case
  doctest CFSync.SyncAPI

  import ExUnit.CaptureLog

  test "It calls request function with correct data" do
    url = Faker.Internet.url()
    token = Faker.String.base64(12)

    request_function = fn req ->
      assert %{
               method: :get,
               headers: [
                 {"Content-Type", "application/json"},
                 {"authorization", "Bearer " <> ^token}
               ],
               options: [ssl: [{:versions, [:"tlsv1.2"]}]],
               url: ^url
             } = req
    end

    CFSync.SyncAPI.request(url, token, request_function: request_function)
  end

  test "It handles known errors codes" do
    known_codes = [
      {401, :unauthorized, "Unauthorized request"},
      {422, :unprocessable, "Unprocessable Entity"}
    ]

    for {code, atom, msg} <- known_codes do
      request_function = fn _req ->
        {:ok, %{status_code: code}}
      end

      {result, log} =
        with_log(
          [level: :error],
          fn ->
            CFSync.SyncAPI.request("url", "token", request_function: request_function)
          end
        )

      assert {:error, ^atom} = result
      assert log =~ "Contentful request failed: #{msg}"
    end
  end
end
