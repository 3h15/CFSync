defmodule CFSync.Link do
  @moduledoc """
  The `Link` struct holds data from Contentful links. It's provided as
  is and is not configurable, so if you need more fields than those currently mapped,
  feel free to send a PR.

  Links are used in Contentful for relations. A single-entry or single-asset
  relation field will contain a `Link` struct (or `nil`). Multi-entry and multi-asset relation
  fields contain a list of `Link` structs (or `[]`).

  Links can be resolved through `CFSync.get_link_target/2`.
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
