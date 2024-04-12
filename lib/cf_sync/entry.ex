defmodule CFSync.Entry do
  @moduledoc """
  The `Entry` struct holds standard data from Contentful entries. It's provided as
  is and is not configurable, so if you need more fields than those currently mapped,
  feel free to send a PR.
  """

  require Logger

  alias CFSync.Entry.Fields

  @enforce_keys [:store, :id, :revision, :space_id, :content_type, :fields]
  defstruct [:store, :id, :revision, :space_id, :content_type, :fields]

  @type t :: %__MODULE__{
          store: CFSync.store(),
          id: binary(),
          revision: integer(),
          space_id: binary(),
          content_type: atom(),
          fields: Fields.t()
        }

  @doc false
  @spec new(map, map, binary, CFSync.store()) :: t()
  def new(
        %{
          "sys" => %{
            "id" => id,
            "type" => "Entry",
            "revision" => revision,
            "contentType" => %{
              "sys" => %{
                "id" => content_type
              }
            },
            "space" => %{
              "sys" => %{
                "id" => space_id
              }
            }
          },
          "fields" => fields
        },
        content_types,
        locale,
        store
      ) do
    case get_config_for_content_type(content_types, content_type) do
      {:ok, config} ->
        fields = config.fields_module.new({fields, locale})

        %__MODULE__{
          store: store,
          id: id,
          revision: revision,
          space_id: space_id,
          content_type: config.content_type,
          fields: fields
        }

      :error ->
        %__MODULE__{
          store: store,
          id: id,
          revision: revision,
          space_id: space_id,
          content_type: :unknown,
          fields: nil
        }
    end
  end

  defp get_config_for_content_type(content_types, content_type) when is_binary(content_type) do
    with {:ok, config} <- fetch_config_for_content_type(content_types, content_type),
         :ok <- validate_config(config) do
      {:ok, config}
    else
      {:error, :no_config_for_content_type} ->
        error(content_type, "No mapping provided for this content type.")

      {:error, :invalid_config} ->
        error(content_type, "Invalid mapping.")

      {:error, :undefined_fields_module, mod} ->
        error(content_type, "Undefined fields module: #{inspect(mod)}.")
    end
  end

  defp error(content_type, msg) do
    Logger.error("CFSync mapping error for content type \"#{content_type}\":")
    Logger.error(msg)
    :error
  end

  defp fetch_config_for_content_type(content_types, content_type) do
    case Map.fetch(content_types, content_type) do
      {:ok, config} -> {:ok, config}
      _ -> {:error, :no_config_for_content_type}
    end
  end

  defp validate_config(%{
         content_type: content_type,
         fields_module: fields_module
       })
       when is_atom(content_type) and is_atom(fields_module) do
    case Code.ensure_loaded(fields_module) do
      {:module, ^fields_module} -> :ok
      _ -> {:error, :undefined_fields_module, fields_module}
    end
  end

  defp validate_config(_invalid) do
    {:error, :invalid_config}
  end
end
