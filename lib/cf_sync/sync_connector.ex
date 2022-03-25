defmodule CFSync.SyncConnector do
  @moduledoc """
  This module handles Contentful sync API connection
  The only public function is sync(), which can be called with nil or with a URL
  With nil, it makes an "initial" sync request
  With URL, it makes subsequent "delta" sync requests
  """

  @http_client_module Application.compile_env(
                        :cf_sync,
                        :http_client_module,
                        CFSync.HTTPClient.HTTPoison
                      )

  alias CFSync.Space

  def sync(space, url \\ nil)
  def sync(%Space{} = space, nil), do: sync(space, initial_url(space))

  def sync(%Space{} = space, url), do: @http_client_module.fetch(url, space.token)

  defp initial_url(%Space{root_url: u, space_id: s}), do: "#{u}spaces/#{s}/sync/?initial=true"
end
