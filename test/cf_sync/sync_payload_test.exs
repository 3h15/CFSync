defmodule CFSync.SyncPayloadTest do
  use ExUnit.Case, async: true

  doctest CFSync.SyncPayload

  alias CFSync.SyncPayload
  alias CFSync.Entry
  alias CFSync.Asset

  test "new/2 creates a valid struct with next page URL" do
    locale = Faker.String.base64(2)
    content_types = CFSyncTest.Entries.mapping()
    url = Faker.String.base64(20)

    data = %{
      "nextPageUrl" => url,
      "items" => []
    }

    assert %SyncPayload{next_url: ^url, next_url_type: :next_page} =
             SyncPayload.new(data, content_types, locale)
  end

  test "new/2 creates a valid struct with next sync URL" do
    locale = Faker.String.base64(2)
    content_types = CFSyncTest.Entries.mapping()
    url = Faker.String.base64(20)

    data = %{
      "nextSyncUrl" => url,
      "items" => []
    }

    assert %SyncPayload{next_url: ^url, next_url_type: :next_sync} =
             SyncPayload.new(data, content_types, locale)
  end

  test "new/2 correctly dispatches deltas" do
    locale = Faker.String.base64(2)
    content_types = CFSyncTest.Entries.mapping()

    item = fn
      Asset, id, type ->
        %{
          "sys" => %{"id" => id, "type" => type},
          "fields" => %{
            "title" => %{locale => ""},
            "description" => %{locale => ""},
            "file" => %{
              locale => %{
                "contentType" => "",
                "fileName" => "",
                "url" => "",
                "details" => %{
                  "image" => %{
                    "width" => 0,
                    "height" => 0
                  },
                  "size" => 0
                }
              }
            }
          }
        }

      Entry, id, type ->
        %{
          "sys" => %{
            "id" => id,
            "type" => type,
            "revision" => 1,
            "contentType" => %{"sys" => %{"id" => "page"}},
            "space" => %{"sys" => %{"id" => "anyspace"}}
          },
          "fields" => %{}
        }
    end

    data = %{
      "nextSyncUrl" => "",
      "items" => [
        item.(Entry, "1-upsert-entry", "Entry"),
        item.(Asset, "2-del-asset", "DeletedAsset"),
        item.(Entry, "3-upsert-entry", "Entry"),
        item.(Asset, "4-del-asset", "DeletedAsset"),
        item.(Entry, "5-del-entry", "DeletedEntry"),
        item.(Asset, "6-upsert-asset", "Asset")
      ]
    }

    %SyncPayload{deltas: deltas} = SyncPayload.new(data, content_types, locale)

    assert length(deltas) == 6

    assert [
             {:upsert, %Entry{id: "1-upsert-entry"}},
             {:delete_asset, "2-del-asset"},
             {:upsert, %Entry{id: "3-upsert-entry"}},
             {:delete_asset, "4-del-asset"},
             {:delete_entry, "5-del-entry"},
             {:upsert, %Asset{id: "6-upsert-asset"}}
           ] = deltas
  end
end
