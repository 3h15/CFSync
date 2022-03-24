defmodule CFSync.Link do
  @moduledoc """
  In Contentful, 'Links' are references to other entries or assets
  This is a struct to handle these data
  """
  @enforce_keys [:type, :id]

  defstruct [:type, :id]

  @type t :: %__MODULE__{
          type: :asset | :entry,
          id: binary()
        }

  def new(%{
        "sys" => %{
          "linkType" => type,
          "id" => id
        }
      }) do
    %__MODULE__{
      type: type(type),
      id: id
    }
  end

  defp type("Asset"), do: :asset
  defp type("Entry"), do: :entry
end
