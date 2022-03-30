defmodule CFSyncTest.Fields.Page do
  alias CFSync.Entry
  alias CFSync.Asset
  # alias CFSync.Link

  import CFSync.Entry.Extractors

  @behaviour Entry.FieldsConstructor

  @enforce_keys [
    :name,
    :boolean,
    :integer,
    :decimal,
    :date,
    :datetime,
    :one_asset,
    :many_assets,
    :one_link,
    :many_links
  ]
  defstruct [
    :name,
    :boolean,
    :integer,
    :decimal,
    :date,
    :datetime,
    :one_asset,
    :many_assets,
    :one_link,
    :many_links
  ]

  @type t() :: %__MODULE__{
          name: binary,
          boolean: boolean | nil,
          integer: number | nil,
          decimal: number | nil,
          date: Date.t() | nil,
          datetime: DateTime.t() | nil,
          one_asset: Asset.t() | nil,
          many_assets: [Asset.t()] | nil
        }

  @impl true
  def new(data) do
    %__MODULE__{
      name: extract_binary(data, "name", "No name"),
      boolean: extract_boolean(data, "boolean"),
      integer: extract_number(data, "integer"),
      decimal: extract_number(data, "decimal"),
      date: extract_date(data, "date"),
      datetime: extract_datetime(data, "datetime"),
      one_asset: extract_link(data, "one_asset"),
      many_assets: extract_links(data, "many_assets"),
      one_link: extract_link(data, "one_link"),
      many_links: extract_links(data, "many_links")
    }
  end
end
