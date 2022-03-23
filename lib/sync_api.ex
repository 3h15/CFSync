defmodule CFSync.SyncAPI do
  require Logger

  def request(url, token, options) do
    request_function = Keyword.get(options, :request_function, &Httpoison.request/1)

    req = %HTTPoison.Request{
      method: :get,
      headers: [
        {"Content-Type", "application/json"},
        {"authorization", "Bearer #{token}"}
      ],
      options: [ssl: [{:versions, [:"tlsv1.2"]}]],
      url: url
    }

    case request_function.(req) do
      {:ok, resp} -> extract_response(resp)
      error -> error
    end
  end

  defp extract_response(%{status_code: 200, body: body}) do
    {:ok, Jason.decode!(body)}
  end

  defp extract_response(%{status_code: 401}) do
    Logger.error("Contentful request failed: Unauthorized request.")
    {:error, :unauthorized}
  end

  defp extract_response(%{status_code: 422}) do
    Logger.error("Contentful request failed: Unprocessable Entity.")
    {:error, :unprocessable}
  end

  defp extract_response(%{status_code: 429} = response) do
    Logger.error("Contentful request failed: Rate limited.")
    # retry after delay
    delay =
      case response.headers |> List.keyfind("X-Contentful-RateLimit-Reset", 0) do
        {_header, delay} -> String.to_integer(delay)
        _ -> 10
      end

    {:rate_limited, delay}
  end

  defp extract_response(%{status_code: unknown_status}) do
    Logger.error("Unhandled Contentful status code: " <> Integer.to_string(unknown_status))
    {:error, :unknown}
  end
end
