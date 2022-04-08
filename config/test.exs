import Mix.Config

config :cf_sync, :httpoison_module, CFSyncTest.FakeHTTPoison

config :cf_sync, :http_client_module, CFSyncTest.FakeHTTPClient
