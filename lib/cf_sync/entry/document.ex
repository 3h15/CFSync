defmodule CFSync.Entry.Document do
  alias CFSync.Entry.Extractors

  @spec get_value(Extractors.data(), String.t(), keyword()) :: any()
  def get_value(%{fields: fields, locales: locales, locale: locale}, field, opts \\ []) do
    %{
      fields: fields,
      field: field,
      locale: locales[locale],
      force_locale: locales[opts[:force_locale]],
      fallback_locale: locales[opts[:fallback_locale]],
      value: nil
    }
    |> maybe_get_value_from(:force_locale)
    |> maybe_get_value_from(:locale)
    |> maybe_get_value_from(:fallback_locale)
    |> Map.get(:value)
  end

  defp maybe_get_value_from(%{force_locale: nil} = params, :force_locale) do
    params
  end

  defp maybe_get_value_from(%{force_locale: fl} = params, :locale) when fl != nil do
    params
  end

  defp maybe_get_value_from(%{fields: fields, field: field, value: nil} = params, locale_key) do
    locale = params[locale_key]
    %{params | value: fields[field][locale]}
  end

  defp maybe_get_value_from(params, _) do
    params
  end
end
