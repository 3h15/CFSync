defmodule CFSync.Asset do
  @moduledoc """
  The `Asset` struct holds data from Contentful assets. It's provided as
  is and is not configurable, so if you need more fields than those currently mapped,
  feel free to send a PR.
  """

  @enforce_keys [
    :store,
    :id,
    :content_type,
    :space_id,
    :locale,
    :title,
    :description,
    :file_name,
    :url,
    :width,
    :height,
    :size
  ]
  defstruct [
    :store,
    :id,
    :content_type,
    :space_id,
    :locale,
    :title,
    :description,
    :file_name,
    :url,
    :width,
    :height,
    :size
  ]

  @type t :: %__MODULE__{
          store: CFSync.store(),
          id: binary(),
          content_type: binary(),
          space_id: binary(),
          locale: binary(),
          title: binary(),
          description: binary(),
          file_name: binary(),
          url: binary(),
          width: integer(),
          height: integer(),
          size: integer()
        }

  @doc false
  @spec new(map, binary(), CFSync.store()) :: t()
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
        locale,
        store
      ) do
    title = fields["title"][locale] || ""
    description = fields["description"][locale] || ""
    content_type = fields["file"][locale]["contentType"] || ""
    file_name = fields["file"][locale]["fileName"] || ""
    url = fields["file"][locale]["url"] || ""
    width = fields["file"][locale]["details"]["image"]["width"] || 0
    height = fields["file"][locale]["details"]["image"]["height"] || 0
    size = fields["file"][locale]["details"]["size"] || 0

    %__MODULE__{
      store: store,
      id: id,
      space_id: space_id,
      content_type: content_type,
      locale: locale,
      title: title,
      description: description,
      file_name: file_name,
      url: url,
      width: width,
      height: height,
      size: size
    }
  end
end
