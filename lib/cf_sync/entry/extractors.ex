defmodule CFSync.Entry.Extractors do
  @moduledoc """
  Utility functions to extract data from contenful JSON.
  """
  require Logger

  alias CFSync.Link
  alias CFSync.RichText

  @typedoc """
  Entry's payload as provided to `c:CFSync.Entry.Fields.new/1`
  """
  @opaque data() :: {map, binary}

  @doc """
  Returns value of `field_name` as a `binary`.

  - `data` is the entry's payload as provided to `c:CFSync.Entry.Fields.new/1`
  - `field_name` is the field's id in Contentful (ie. What is configured in Contentful app)

  Returns `default` on failure (field empty, not a string...)
  """
  @spec extract_binary(data(), String.t(), nil | String.t()) :: nil | String.t()
  def extract_binary({data, locale} = _data, field_name, default \\ nil) do
    case extract(data, field_name, locale) do
      v when is_binary(v) -> v
      _ -> default
    end
  end

  @doc """
  Returns value of `field_name` as a `boolean`.

  - `data` is the entry's payload as provided to `c:CFSync.Entry.Fields.new/1`
  - `field_name` is the field's id in Contentful (ie. What is configured in Contentful app)

  Returns `default` on failure (field empty, not a boolean...)
  """
  @spec extract_boolean(data(), String.t(), nil | boolean) :: nil | boolean
  def extract_boolean({data, locale} = _data, field_name, default \\ nil) do
    case extract(data, field_name, locale) do
      v when is_boolean(v) -> v
      _ -> default
    end
  end

  @doc """
  Returns value of `field_name` as a `number`.

  - `data` is the entry's payload as provided to `c:CFSync.Entry.Fields.new/1`
  - `field_name` is the field's id in Contentful (ie. What is configured in Contentful app)

  Be careful with the result as it can be either an integer or float, depending
  of it's value. A contentful decimal value of 1.0 will be stored as 1 in the JSON
  and read as an integer by JASON.

  Returns `default` on failure (field empty, not a number...)
  """
  @spec extract_number(data(), String.t(), nil | number) :: nil | number
  def extract_number({data, locale} = _data, field_name, default \\ nil) do
    case extract(data, field_name, locale) do
      v when is_number(v) -> v
      _ -> default
    end
  end

  @doc """
  Returns value of `field_name` as a `Date`.

  - `data` is the entry's payload as provided to `c:CFSync.Entry.Fields.new/1`
  - `field_name` is the field's id in Contentful (ie. What is configured in Contentful app)

  Returns `default` on failure (field empty, invalid format, invalid date...)
  """
  @spec extract_date(data(), String.t(), nil | Date.t()) :: nil | Date.t()
  def extract_date({data, locale} = _data, field_name, default \\ nil) do
    with v when is_binary(v) <- extract(data, field_name, locale),
         {:ok, date} <- Date.from_iso8601(v) do
      date
    else
      _ ->
        default
    end
  end

  @doc """
  Returns value of `field_name` as a `DateTime`.

  - `data` is the entry's payload as provided to `c:CFSync.Entry.Fields.new/1`
  - `field_name` is the field's id in Contentful (ie. What is configured in Contentful app)

  Returns `default` on failure (field empty, invalid format, invalid datetime...)
  """
  @spec extract_datetime(data(), String.t(), nil | DateTime.t()) :: nil | DateTime.t()
  def extract_datetime({data, locale} = _data, field_name, default \\ nil) do
    with v when is_binary(v) <- extract(data, field_name, locale),
         {:ok, date, _offset} <- DateTime.from_iso8601(v) do
      date
    else
      _ ->
        default
    end
  end

  @doc """
  Returns value of `field_name` as a `map`.

  - `data` is the entry's payload as provided to `c:CFSync.Entry.Fields.new/1`
  - `field_name` is the field's id in Contentful (ie. What is configured in Contentful app)

  Returns `default` on failure (field empty, not a map...)
  """
  @spec extract_map(data(), String.t(), nil | map) :: nil | map
  def extract_map({data, locale} = _data, field_name, default \\ nil) do
    case extract(data, field_name, locale) do
      v when is_map(v) -> v
      _ -> default
    end
  end

  @doc """
  Returns value of `field_name` as a `list`.

  - `data` is the entry's payload as provided to `c:CFSync.Entry.Fields.new/1`
  - `field_name` is the field's id in Contentful (ie. What is configured in Contentful app)

  Returns `default` on failure (field empty, not a list...)
  """
  @spec extract_list(data(), String.t(), nil | list) :: nil | list
  def extract_list({data, locale} = _data, field_name, default \\ nil) do
    case extract(data, field_name, locale) do
      v when is_list(v) -> v
      _ -> default
    end
  end

  @doc """
  Returns value of `field_name` as a `CFSync.Link`.

  - `data` is the entry's payload as provided to `c:CFSync.Entry.Fields.new/1`
  - `field_name` is the field's id in Contentful (ie. What is configured in Contentful app)

  Returns `default` on failure (field empty, not a link...)
  """
  @spec extract_link(data(), String.t(), nil | Link.t()) :: nil | Link.t()
  def extract_link({data, locale} = _data, field_name, default \\ nil) do
    with link_data when is_map(link_data) <- extract(data, field_name, locale),
         %Link{} = link <- try_link(link_data) do
      link
    else
      _ -> default
    end
  end

  @doc """
  Returns value of `field_name` as a list of `CFSync.Link`.

  - `data` is the entry's payload as provided to `c:CFSync.Entry.Fields.new/1`
  - `field_name` is the field's id in Contentful (ie. What is configured in Contentful app)

  Returns `default` on failure (field empty, not a list...)
  """
  @spec extract_links(data(), String.t(), nil | list(Link.t())) :: nil | list(Link.t())
  def extract_links({data, locale} = _data, field_name, default \\ nil) do
    case extract(data, field_name, locale) do
      links when is_list(links) ->
        links
        |> Enum.map(&try_link/1)
        |> Enum.reject(&is_nil/1)

      _ ->
        default
    end
  end

  @doc """
  Returns value of `field_name` as `CFSync.RichText` tree.

  - `data` is the entry's payload as provided to `c:CFSync.Entry.Fields.new/1`
  - `field_name` is the field's id in Contentful (ie. What is configured in Contentful app)

  Returns `default` on failure (field empty, not a richtext...)
  """
  @spec extract_rich_text(data(), String.t(), nil | RichText.t()) :: nil | RichText.t()
  def extract_rich_text({data, locale} = _data, field_name, default \\ nil) do
    case extract(data, field_name, locale) do
      rt when is_map(rt) -> RichText.new(rt)
      _ -> default
    end
  end

  @doc """
  Returns value of `field_name` as an `atom`.

  - `data` is the entry's payload as provided to `c:CFSync.Entry.Fields.new/1`
  - `field_name` is the field's id in Contentful (ie. What is configured in Contentful app)
  - `mapping` is a map of `"value" => :atom` used to find which atom correspond to the field's value

  Returns `default` on failure (field empty, no mapping...)
  """
  @spec extract_atom(data(), String.t(), %{any() => atom()}, atom) :: nil | atom
  def extract_atom({data, locale} = _data, field_name, mapping, default \\ nil) do
    v = extract(data, field_name, locale)

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
