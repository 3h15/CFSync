defmodule CFSync.Entry do
  @moduledoc """
  Base entry struct
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
        lang
      ) do
    content_type = parse_content_type(content_type)

    fields = new_fields(content_type, fields, lang)

    %__MODULE__{
      id: id,
      revision: revision,
      content_type: content_type,
      fields: fields
    }
  end

  @spec get_name(__MODULE__.t()) :: binary
  def get_name(this) do
    Fields.get_name(this.fields)
  end

  defp new_fields(:unknown, _fields_data, _lang), do: nil

  defp new_fields(content_type, fields_data, lang) when is_atom(content_type) do
    with {:ok, mod} <- fetch_fields_module(content_type),
         {:module, ^mod} <- load_fields_module(mod) do
      mod.new({fields_data, lang})
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
