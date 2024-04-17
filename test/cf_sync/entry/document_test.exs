defmodule CFSync.Entry.DocumentTest do
  use ExUnit.Case, async: true

  doctest CFSync.Entry.Document

  alias CFSync.Entry.Document

  @opts %{
    no_opts: [],
    force: [force_locale: :fr],
    fallback: [fallback_locale: :de],
    force_and_fallback: [force_locale: :fr, fallback_locale: :de]
  }

  @fields %{
    full_field: %{
      "field_name" => %{"en_US" => "ENGLISH", "fr_FR" => "FRENCH", "de_DE" => "GERMAN"}
    },
    missing_de: %{"field_name" => %{"en_US" => "ENGLISH", "fr_FR" => "FRENCH"}},
    missing_fr: %{"field_name" => %{"en_US" => "ENGLISH", "de_DE" => "GERMAN"}},
    missing_fr_de: %{"field_name" => %{"en_US" => "ENGLISH"}},
    missing_en: %{"field_name" => %{"fr_FR" => "FRENCH", "de_DE" => "GERMAN"}},
    empty_field: %{"field_name" => %{}},
    nil_field: %{"field_name" => nil},
    nil_de: %{"field_name" => %{"en_US" => "ENGLISH", "fr_FR" => "FRENCH", "de_DE" => nil}},
    nil_fr: %{"field_name" => %{"en_US" => "ENGLISH", "fr_FR" => nil, "de_DE" => "GERMAN"}},
    nil_fr_de: %{"field_name" => %{"en_US" => "ENGLISH", "fr_FR" => nil, "de_DE" => nil}},
    nil_en: %{"field_name" => %{"en_US" => nil, "fr_FR" => "FRENCH", "de_DE" => "GERMAN"}},
    nil_all: %{"field_name" => %{"en_US" => nil, "fr_FR" => nil, "de_DE" => nil}},
    missing_field: %{}
  }

  @expected_values %{
    no_opts: %{
      full_field: "ENGLISH",
      missing_de: "ENGLISH",
      missing_fr: "ENGLISH",
      missing_fr_de: "ENGLISH",
      missing_en: nil,
      empty_field: nil,
      nil_field: nil,
      nil_de: "ENGLISH",
      nil_fr: "ENGLISH",
      nil_fr_de: "ENGLISH",
      nil_en: nil,
      nil_all: nil,
      missing_field: nil
    },
    force: %{
      full_field: "FRENCH",
      missing_de: "FRENCH",
      missing_fr: nil,
      missing_fr_de: nil,
      missing_en: "FRENCH",
      empty_field: nil,
      nil_field: nil,
      nil_de: "FRENCH",
      nil_fr: nil,
      nil_fr_de: nil,
      nil_en: "FRENCH",
      nil_all: nil,
      missing_field: nil
    },
    fallback: %{
      full_field: "ENGLISH",
      missing_de: "ENGLISH",
      missing_fr: "ENGLISH",
      missing_fr_de: "ENGLISH",
      missing_en: "GERMAN",
      empty_field: nil,
      nil_field: nil,
      nil_de: "ENGLISH",
      nil_fr: "ENGLISH",
      nil_fr_de: "ENGLISH",
      nil_en: "GERMAN",
      nil_all: nil,
      missing_field: nil
    },
    force_and_fallback: %{
      full_field: "FRENCH",
      missing_de: "FRENCH",
      missing_fr: "GERMAN",
      missing_fr_de: nil,
      missing_en: "FRENCH",
      empty_field: nil,
      nil_field: nil,
      nil_de: "FRENCH",
      nil_fr: "GERMAN",
      nil_fr_de: nil,
      nil_en: "FRENCH",
      nil_all: nil,
      missing_field: nil
    }
  }

  test "get_value/3 returns the expected value" do
    for {opts_key, values} <- @expected_values, {field_key, expected_value} <- values do
      value =
        Document.get_value(
          %{
            fields: @fields[field_key],
            locales: %{en: "en_US", fr: "fr_FR", de: "de_DE"},
            locale: :en
          },
          "field_name",
          @opts[opts_key]
        )

      assert value == expected_value, """
      Expected #{inspect(expected_value)} but got #{inspect(value)} for field #{inspect(field_key)} #{inspect(@fields[field_key])} with opts #{inspect(@opts[opts_key])}
      """
    end
  end
end
