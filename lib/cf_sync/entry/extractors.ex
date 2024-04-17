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
  @opaque data() :: %{
            fields: map(),
            cf_locale: String.t(),
            store: CFSync.store(),
            locale: atom()
          }

  @doc """
  Returns value of `field_name` as a `binary`.

  - `data` is the entry's payload as provided to `c:CFSync.Entry.Fields.new/1`
  - `field_name` is the field's id in Contentful (ie. What is configured in Contentful app)

  Returns `default` on failure (field empty, not a string...)
  """
  @spec extract_binary(data(), String.t(), keyword()) :: nil | String.t()
  def extract_binary(data, field_name, opts \\ []) do
    default = Keyword.get(opts, :default, nil)

    case extract(data, field_name, opts) do
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
  @spec extract_boolean(data(), String.t(), keyword()) :: nil | boolean
  def extract_boolean(data, field_name, opts \\ []) do
    default = Keyword.get(opts, :default, nil)

    case extract(data, field_name, opts) do
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
  @spec extract_number(data(), String.t(), keyword()) :: nil | number
  def extract_number(data, field_name, opts \\ []) do
    default = Keyword.get(opts, :default, nil)

    case extract(data, field_name, opts) do
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
  @spec extract_date(data(), String.t(), keyword()) :: nil | Date.t()
  def extract_date(data, field_name, opts \\ []) do
    default = Keyword.get(opts, :default, nil)

    with v when is_binary(v) <- extract(data, field_name, opts),
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
  @spec extract_datetime(data(), String.t(), keyword()) :: nil | DateTime.t()
  def extract_datetime(data, field_name, opts \\ []) do
    default = Keyword.get(opts, :default, nil)

    with v when is_binary(v) <- extract(data, field_name, opts),
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
  @spec extract_map(data(), String.t(), keyword()) :: nil | map
  def extract_map(data, field_name, opts \\ []) do
    default = Keyword.get(opts, :default, nil)

    case extract(data, field_name, opts) do
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
  @spec extract_list(data(), String.t(), keyword()) :: nil | list
  def extract_list(data, field_name, opts \\ []) do
    default = Keyword.get(opts, :default, nil)

    case extract(data, field_name, opts) do
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
  @spec extract_link(data(), String.t(), keyword()) :: nil | Link.t()
  def extract_link(data, field_name, opts \\ []) do
    default = Keyword.get(opts, :default, nil)

    with link_data when is_map(link_data) <- extract(data, field_name, opts),
         %Link{} = link <- try_link(link_data, data.store, data.locale) do
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
  @spec extract_links(data(), String.t(), keyword()) :: nil | list(Link.t())
  def extract_links(data, field_name, opts \\ []) do
    default = Keyword.get(opts, :default, nil)

    case extract(data, field_name, opts) do
      links when is_list(links) ->
        links
        |> Enum.map(&try_link(&1, data.store, data.locale))
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
  @spec extract_rich_text(data(), String.t(), keyword()) :: nil | RichText.t()
  def extract_rich_text(data, field_name, opts \\ []) do
    default = Keyword.get(opts, :default, nil)

    case extract(data, field_name, opts) do
      rt when is_map(rt) -> RichText.new(rt, data.store, data.locale)
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
  @spec extract_atom(data(), String.t(), %{any() => atom()}, keyword()) :: nil | atom
  def extract_atom(data, field_name, mapping, opts \\ []) do
    default = Keyword.get(opts, :default, nil)
    v = extract(data, field_name, opts)

    case mapping[v] do
      nil -> default
      value -> value
    end
  end

  @doc """
  Returns value of `field_name` processed by `fun`.

  - `data` is the entry's payload as provided to `c:CFSync.Entry.Fields.new/1`
  - `field_name` is the field's id in Contentful (ie. What is configured in Contentful app)
  - `fun` is a function of arity 1

  Returns `nil` if the field is not included in the payload.
  """
  @spec extract_custom(data(), String.t(), (any() -> any()), keyword) :: any()
  def extract_custom(data, field_name, fun, opts \\ []) do
    v = extract(data, field_name, opts)
    fun.(v)
  end

  defp extract(
         %{
           fields: fields,
           cf_locale: cf_locale
         } = _data,
         field,
         _opts
       ) do
    fields[field][cf_locale]
  end

  defp try_link(link_data, store, locale) do
    Link.new(link_data, store, locale)
  rescue
    _ ->
      Logger.error("Bad link data:\n#{inspect(link_data)}")
      nil
  end
end
