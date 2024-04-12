defmodule CFSync.SyncPayloadTest do
  use ExUnit.Case, async: true

  doctest CFSync.SyncPayload

  alias CFSync.SyncPayload
  alias CFSync.Entry
  alias CFSync.Asset

  test "new/2 creates a valid struct with next page URL" do
    url = Faker.String.base64(20)
    data = %{"nextPageUrl" => url, "items" => []}
    assert %SyncPayload{next_url: ^url, next_url_type: :next_page} = SyncPayload.new(data)
  end

  test "new/2 creates a valid struct with next sync URL" do
    url = Faker.String.base64(20)
    data = %{"nextSyncUrl" => url, "items" => []}
    assert %SyncPayload{next_url: ^url, next_url_type: :next_sync} = SyncPayload.new(data)
  end

  test "new/2 correctly dispatches deltas" do
    item = fn
      Asset, id, type ->
        %{
          "sys" => %{"id" => id, "type" => type, "space" => %{"sys" => %{"id" => "anyspace"}}},
          "fields" => :fields
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
          "fields" => :fields
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

    %SyncPayload{deltas: deltas} = SyncPayload.new(data)

    assert length(deltas) == 6

    assert [
             {:upsert_entry, item_0},
             {:delete_asset, "2-del-asset"},
             {:upsert_entry, item_2},
             {:delete_asset, "4-del-asset"},
             {:delete_entry, "5-del-entry"},
             {:upsert_asset, item_5}
           ] = deltas

    assert item_0 == Enum.at(data["items"], 0)
    assert item_2 == Enum.at(data["items"], 2)
    assert item_5 == Enum.at(data["items"], 5)
  end
end
