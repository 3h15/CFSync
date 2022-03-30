defmodule CFSync.Entry do
  @moduledoc """
  The `Entry` struct holds standard data from Contentful entries. It's provided as
  is and is not configurable, so if you need more fields than those currently mapped,
  feel free to send a PR.
  """

  require Logger

  alias CFSync.Entry.Fields

  @fields_modules Application.compile_env(:cf_sync, :fields_modules, %{})

  @enforce_keys [:id, :revision, :content_type, :fields]
  defstruct [:id, :revision, :content_type, :fields]

  @type t :: %__MODULE__{
          id: binary(),
          revision: integer(),
          content_type: atom(),
          fields: Fields.t()
        }

  @doc false
  @spec new(map, binary) :: t()
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
            }
          },
          "fields" => fields
        },
        locale
      ) do
    content_type = parse_content_type(content_type)

    fields = new_fields(content_type, fields, locale)

    %__MODULE__{
      id: id,
      revision: revision,
      content_type: content_type,
      fields: fields
    }
  end

  defp new_fields(:unknown, _fields_data, _locale), do: nil

  defp new_fields(content_type, fields_data, locale) when is_atom(content_type) do
    with {:ok, mod} <- fetch_fields_module(content_type),
         {:module, ^mod} <- load_fields_module(mod) do
      mod.new({fields_data, locale})
    else
      {:error, :no_config_for_content_type} ->
        Logger.error("No configured fields module for content_type: #{inspect(content_type)}")
        nil

      {:error, :undefined_fields_module, mod} ->
        Logger.error("Undefined module: #{inspect(mod)}")
        nil
    end
  end

  defp fetch_fields_module(content_type) do
    case Map.fetch(@fields_modules, content_type) do
      {:ok, mod} when is_atom(mod) ->
        {:ok, mod}

      _ ->
        {:error, :no_config_for_content_type}
    end
  end

  defp load_fields_module(mod) do
    case Code.ensure_loaded(mod) do
      {:module, ^mod} ->
        {:module, mod}

      _ ->
        {:error, :undefined_fields_module, mod}
    end
  end

  defp parse_content_type(content_type) do
    content_type
    |> Inflex.underscore()
    |> String.to_existing_atom()
  rescue
    _ ->
      Logger.error("Unknown entry content_type: #{inspect(content_type)}")
      :unknown
  end
end
