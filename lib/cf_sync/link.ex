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
  @enforce_keys [:store, :type, :id, :locale]

  defstruct [:store, :type, :id, :locale]

  @type t :: %__MODULE__{
          store: CFSync.store(),
          type: :asset | :entry,
          id: binary(),
          locale: atom()
        }

  def new(
        %{
          "sys" => %{
            "linkType" => type,
            "id" => id
          }
        },
        store,
        locale
      ) do
    %__MODULE__{
      store: store,
      type: type(type),
      id: id,
      locale: locale
    }
  end

  defp type("Asset"), do: :asset
  defp type("Entry"), do: :entry
end
