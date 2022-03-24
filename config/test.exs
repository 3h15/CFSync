import Mix.Config

config :cf_sync, :httpoison_module, CFSync.FakeHTTPoison

config :cf_sync, :http_client_module, CFSync.FakeHTTPClient
