defmodule CFSync.Asset do
  @moduledoc """
  The `Asset` struct holds data from Contentful assets. It's provided as
  is and is not configurable, so if you need more fields than those currently mapped,
  feel free to send a PR.
  """

  @enforce_keys [
    :store,
    :space_id,
    :id,
    :locale,
    :title,
    :description,
    # This is the content type of the file, not an equivalent to the content type of an entry
    :content_type,
    :file_name,
    :url,
    :width,
    :height,
    :size
  ]
  defstruct [
    :store,
    :space_id,
    :id,
    :locale,
    :title,
    :description,
    :content_type,
    :file_name,
    :url,
    :width,
    :height,
    :size
  ]

  @type t :: %__MODULE__{
          store: CFSync.store(),
          space_id: binary(),
          id: binary(),
          locale: atom(),
          title: binary(),
          description: binary(),
          content_type: binary(),
          file_name: binary(),
          url: binary(),
          width: integer(),
          height: integer(),
          size: integer()
        }

  @doc false
  # locale is the "CFSync" locale: it is an atom, used as a key in ETS tables.
  # cf_locale is the Contentful locale: it is a binary, used as a key in the Contentful API.
  @spec new(
          data :: map(),
          locales :: map(),
          store :: CFSync.store(),
          locale :: atom()
        ) :: t()
  def new(
        %{
          "sys" => %{
            "id" => id,
            "type" => "Asset",
            "space" => %{
              "sys" => %{
                "id" => space_id
              }
            }
          },
          "fields" => fields
        },
        locales,
        store,
        locale
      ) do
    cf_locale = Map.get(locales, locale)

    if !cf_locale or cf_locale == "" do
      raise "No locale mapping for #{inspect(locale)}"
    end

    title = fields["title"][cf_locale] || ""
    description = fields["description"][cf_locale] || ""
    content_type = fields["file"][cf_locale]["contentType"] || ""
    file_name = fields["file"][cf_locale]["fileName"] || ""
    url = fields["file"][cf_locale]["url"] || ""
    width = fields["file"][cf_locale]["details"]["image"]["width"] || 0
    height = fields["file"][cf_locale]["details"]["image"]["height"] || 0
    size = fields["file"][cf_locale]["details"]["size"] || 0

    %__MODULE__{
      store: store,
      space_id: space_id,
      id: id,
      locale: locale,
      title: title,
      description: description,
      content_type: content_type,
      file_name: file_name,
      url: url,
      width: width,
      height: height,
      size: size
    }
  end
end
