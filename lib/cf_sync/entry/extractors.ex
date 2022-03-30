defmodule CFSync.Entry.Extractors do
  @moduledoc """
  Utility functions to extract data from contenful json.
  All these functions MUST return:
  - the requested type if possible
  - nil otherwise. (Missing value or type mismatch)
  """
  require Logger

  alias CFSync.Link
  alias CFSync.RichText

  @spec extract_binary({map, binary}, binary, nil | binary) :: nil | binary
  def extract_binary({data, locale}, field, default \\ nil) do
    case extract(data, field, locale) do
      v when is_binary(v) -> v
      _ -> default
    end
  end

  @spec extract_boolean({map, binary}, binary, nil | boolean) :: nil | boolean
  def extract_boolean({data, locale}, field, default \\ nil) do
    case extract(data, field, locale) do
      v when is_boolean(v) -> v
      _ -> default
    end
  end

  @spec extract_number({map, binary}, binary, nil | number) :: nil | number
  def extract_number({data, locale}, field, default \\ nil) do
    case extract(data, field, locale) do
      v when is_number(v) -> v
      _ -> default
    end
  end

  @spec extract_date({map, binary}, binary, nil | Date.t()) :: nil | Date.t()
  def extract_date({data, locale}, field, default \\ nil) do
    with v when is_binary(v) <- extract(data, field, locale),
         {:ok, date} <- Date.from_iso8601(v) do
      date
    else
      _ ->
        default
    end
  end

  @spec extract_datetime({map, binary}, binary, nil | DateTime.t()) :: nil | DateTime.t()
  def extract_datetime({data, locale}, field, default \\ nil) do
    with v when is_binary(v) <- extract(data, field, locale),
         {:ok, date, _offset} <- DateTime.from_iso8601(v) do
      date
    else
      _ ->
        default
    end
  end

  @spec extract_map({map, binary}, binary, nil | map) :: nil | map
  def extract_map({data, locale}, field, default \\ nil) do
    case extract(data, field, locale) do
      v when is_map(v) -> v
      _ -> default
    end
  end

  @spec extract_list({map, binary}, binary, nil | list) :: nil | list
  def extract_list({data, locale}, field, default \\ nil) do
    case extract(data, field, locale) do
      v when is_list(v) -> v
      _ -> default
    end
  end

  @spec extract_link({map, binary}, binary, nil | Link.t()) :: nil | Link.t()
  def extract_link({data, locale}, field, default \\ nil) do
    with link_data when is_map(link_data) <- extract(data, field, locale),
         %Link{} = link <- try_link(link_data) do
      link
    else
      _ -> default
    end
  end

  @spec extract_links({map, binary}, binary, nil | list(Link.t())) :: nil | list(Link.t())
  def extract_links({data, locale}, field, default \\ nil) do
    case extract(data, field, locale) do
      links when is_list(links) ->
        links
        |> Enum.map(&try_link/1)
        |> Enum.reject(&is_nil/1)

      _ ->
        default
    end
  end

  @spec extract_rich_text({map, binary}, binary, nil | RichText.t()) :: nil | RichText.t()
  def extract_rich_text({data, locale}, field, default \\ nil) do
    case extract(data, field, locale) do
      rt when is_map(rt) -> RichText.new(rt)
      _ -> default
    end
  end

  @spec extract_atom({map, binary}, binary, %{any() => atom()}, atom) :: nil | atom
  def extract_atom({data, locale}, field, mapping, default \\ nil) do
    v = extract(data, field, locale)

    case mapping[v] do
      nil -> default
      value -> value
    end
  end

  defp extract(data, field, locale) do
    data[field][locale]
  end

  defp try_link(link_data) do
    Link.new(link_data)
  rescue
    _ ->
      Logger.error("Bad link data:\n#{inspect(link_data)}")
      nil
  end
end
