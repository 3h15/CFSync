import Config

config :cf_sync, :httpoison_module, CFSyncTest.FakeHTTPoison

config :cf_sync, :http_client_module, CFSyncTest.FakeHTTPClient

config :phoenix, :json_library, Jason
