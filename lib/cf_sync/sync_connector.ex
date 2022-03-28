defmodule CFSync.SyncConnector do
  @moduledoc """
  This module handles Contentful sync API connection
  The only public function is sync(), which can be called with nil or with a URL
  With nil, it makes an "initial" sync request
  With URL, it makes subsequent "delta" sync requests
  """

  @behaviour CFSync.SyncConnector.Behaviour

  @http_client_module Application.compile_env(
                        :cf_sync,
                        :http_client_module,
                        CFSync.HTTPClient.HTTPoison
                      )

  alias CFSync.Space
  alias CFSync.SyncPayload

  @impl true
  def sync(space, lang, url \\ nil)
  def sync(%Space{} = space, lang, nil), do: sync(space, lang, initial_url(space))

  def sync(%Space{} = space, lang, url) do
    case @http_client_module.fetch(url, space.token) do
      {:ok, data} ->
        {:ok, SyncPayload.new(data, lang)}

      {:rate_limited, _} = limit ->
        limit

      {:error, _} = error ->
        error
    end
  end

  defp initial_url(%Space{root_url: u, space_id: s}), do: "#{u}spaces/#{s}/sync/?initial=true"
end
