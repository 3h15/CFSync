import Mix.Config

config :cf_sync, :httpoison_module, CFSyncTest.FakeHTTPoison

config :cf_sync, :http_client_module, CFSyncTest.FakeHTTPClient

config :cf_sync, :fields_modules, %{
  page: CFSyncTest.Fields.Page,
  simple_page: CFSyncTest.Fields.SimplePage,
  star: CFSyncTest.Fields.Star,
  content_type_with_undefined_module: CFSyncTest.Fields.UndefinedModule
}

config :cf_sync, :sync_connector_module, CFSyncTest.FakeSyncConnector
