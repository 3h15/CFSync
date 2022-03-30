defmodule CFSync.Asset do
  @moduledoc """
  Asset struct
  """

  @enforce_keys [
    :id,
    :content_type,
    :title,
    :description,
    :file_name,
    :url,
    :width,
    :height,
    :size
  ]
  defstruct [:id, :content_type, :title, :description, :file_name, :url, :width, :height, :size]

  @type t :: %__MODULE__{
          id: binary(),
          content_type: binary(),
          title: binary(),
          description: binary(),
          file_name: binary(),
          url: binary(),
          width: integer(),
          height: integer(),
          size: integer()
        }

  @spec new(map, binary()) :: t()
  def new(
        %{
          "sys" => %{
            "id" => id,
            "type" => "Asset"
          },
          "fields" => fields
        },
        locale
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
      id: id,
      content_type: content_type,
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
