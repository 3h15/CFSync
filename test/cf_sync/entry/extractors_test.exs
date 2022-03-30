defmodule CFSync.Entry.ExtractorsTest do
  use ExUnit.Case, async: true

  doctest CFSync.Entry.Extractors

  alias CFSync.Entry.Extractors

  setup do
    extractors = [
      # {function name, valid value fn, invalid value fn}
      {
        :extract_binary,
        fn -> Faker.String.base64(8) end,
        fn -> Faker.random_between(0, 1000) end
      },
      {
        :extract_boolean,
        fn -> Enum.random([true, false]) end,
        fn -> Faker.random_between(0, 1000) end
      },
      {
        :extract_number,
        fn -> Faker.random_between(0, 1000) end,
        fn -> Faker.String.base64(8) end
      },
      {
        :extract_number,
        fn -> Faker.random_between(0, 1000) / 100 end,
        fn -> Faker.String.base64(8) end
      },
      {
        :extract_date,
        fn ->
          date = Faker.Date.between(~D[0001-01-01], ~D[3000-01-01])
          {Date.to_iso8601(date), date}
        end,
        fn -> Faker.String.base64(5) end
      },
      {
        :extract_datetime,
        fn ->
          date = Faker.DateTime.between(~N[0001-01-01 00:00:00], ~N[3000-01-01 00:00:00])
          {DateTime.to_iso8601(date), date}
        end,
        fn -> Faker.String.base64(5) end
      },
      {
        :extract_map,
        fn ->
          %{
            Faker.String.base64(1) => Faker.random_between(0, 1000),
            Faker.String.base64(2) => Faker.String.base64(5),
            Faker.String.base64(3) => Faker.Date.between(~D[0001-01-01], ~D[3000-01-01]),
            Faker.String.base64(4) => Enum.random([true, false]),
            Faker.String.base64(5) => %{},
            Faker.String.base64(6) => [
              Faker.String.base64(5),
              Faker.random_between(0, 1000),
              Enum.random([true, false])
            ]
          }
        end,
        fn -> Faker.String.base64(8) end
      },
      {
        :extract_list,
        fn ->
          [
            Faker.random_between(0, 1000),
            Faker.String.base64(5),
            Faker.Date.between(~D[0001-01-01], ~D[3000-01-01]),
            Enum.random([true, false]),
            %{},
            [
              Faker.String.base64(5),
              Faker.random_between(0, 1000),
              Enum.random([true, false])
            ]
          ]
        end,
        fn -> Faker.String.base64(8) end
      },
      {
        :extract_link,
        fn ->
          value = %{
            "sys" => %{
              "linkType" => Enum.random(["Asset", "Entry"]),
              "id" => Faker.String.base64(12)
            }
          }

          expected_value = CFSync.Link.new(value)
          {value, expected_value}
        end,
        fn -> Faker.String.base64(8) end
      },
      {
        :extract_link,
        fn ->
          value = %{
            "sys" => %{
              "linkType" => Enum.random(["Asset", "Entry"]),
              "id" => Faker.String.base64(12)
            }
          }

          expected_value = CFSync.Link.new(value)
          {value, expected_value}
        end,
        fn -> %{} end
      },
      {
        :extract_links,
        fn ->
          value = [
            %{
              "sys" => %{
                "linkType" => Enum.random(["Asset", "Entry"]),
                "id" => Faker.String.base64(12)
              }
            },
            %{
              "sys" => %{
                "linkType" => Enum.random(["Asset", "Entry"]),
                "id" => Faker.String.base64(12)
              }
            },
            %{
              "sys" => %{
                "linkType" => Enum.random(["Asset", "Entry"]),
                "id" => Faker.String.base64(12)
              }
            }
          ]

          expected_value = Enum.map(value, &CFSync.Link.new(&1))
          {value, expected_value}
        end,
        fn -> Faker.String.base64(8) end
      },
      {
        :extract_links,
        fn ->
          value = [
            %{
              "sys" => %{
                "linkType" => Enum.random(["Asset", "Entry"]),
                "id" => Faker.String.base64(12)
              }
            },
            %{"invalid" => "link"}
          ]

          expected_value = [value |> List.first() |> CFSync.Link.new()]
          {value, expected_value}
        end,
        fn -> Faker.String.base64(8) end
      },
      {
        :extract_rich_text,
        fn ->
          value = %{
            "nodeType" => "document",
            "content" => []
          }

          expected_value = CFSync.RichText.new(:empty)
          {value, expected_value}
        end,
        fn -> Faker.String.base64(8) end
      }
    ]

    build = fn value_fun ->
      field_name = Faker.String.base64(8)
      locale = Faker.String.base64(2)

      {value, expected_value} =
        case value_fun.() do
          {value, expected_value} -> {value, expected_value}
          value -> {value, value}
        end

      data = %{field_name => %{locale => value}}
      {field_name, locale, expected_value, data}
    end

    %{extractors: extractors, build: build}
  end

  test "extract_*/3 returns value when value and name are valid", %{
    extractors: extractors,
    build: build
  } do
    for {fun, valid_value, _invalid_value} <- extractors do
      {name, locale, expected_value, data} = build.(valid_value)

      result = apply(Extractors, fun, [{data, locale}, name])

      assert result == expected_value,
             "#{fun} with value #{inspect(data)} does not return #{inspect(expected_value)} but #{inspect(result)}"
    end
  end

  test "extract_*/3 returns nil when value is invalid and no default value is provided", %{
    extractors: extractors,
    build: build
  } do
    for {fun, _valid_value, invalid_value} <- extractors do
      {name, locale, _expected_value, data} = build.(invalid_value)
      assert apply(Extractors, fun, [{data, locale}, name]) == nil
    end
  end

  test "extract_*/3 returns nil when key is invalid and no default value is provided", %{
    extractors: extractors,
    build: build
  } do
    for {fun, valid_value, _invalid_value} <- extractors do
      {name, locale, _expected_value, data} = build.(valid_value)
      invalid_name = "err_" <> name
      assert apply(Extractors, fun, [{data, locale}, invalid_name]) == nil
    end
  end

  test "extract_*/3 returns default when value is invalid and a default value is provided", %{
    extractors: extractors,
    build: build
  } do
    for {fun, _valid_value, invalid_value} <- extractors do
      {name, locale, expected_value, data} = build.(invalid_value)
      default_value = expected_value
      assert apply(Extractors, fun, [{data, locale}, name, default_value]) == expected_value
    end
  end

  test "extract_*/3 returns default when key is invalid and a default value is provided", %{
    extractors: extractors,
    build: build
  } do
    for {fun, valid_value, _invalid_value} <- extractors do
      {name, locale, expected_value, data} = build.(valid_value)
      default_value = expected_value
      invalid_name = "err_" <> name

      assert apply(Extractors, fun, [{data, locale}, invalid_name, default_value]) ==
               expected_value
    end
  end

  test "extract_atom/4 returns value when value, name and mapping are valid", %{
    build: build
  } do
    value = Faker.String.base64(8)
    atom = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()

    mapping = %{
      value => atom
    }

    {name, locale, expected_value, data} =
      build.(fn ->
        {value, atom}
      end)

    assert Extractors.extract_atom({data, locale}, name, mapping) == expected_value
  end

  describe "extract_atom/4 without default value" do
    test "returns nil when value has no mapping", %{
      build: build
    } do
      atom = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
      value = Faker.String.base64(8)
      mapping = %{value => atom}

      unmapped_value = Faker.String.base64(8)

      {name, locale, _expected_value, data} = build.(fn -> unmapped_value end)

      assert Extractors.extract_atom({data, locale}, name, mapping) == nil
    end

    test "extract_atom/4 returns nil when name is invalid", %{
      build: build
    } do
      atom = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
      value = Faker.String.base64(8)
      mapping = %{value => atom}

      {name, locale, _expected_value, data} = build.(fn -> value end)

      invalid_name = "err_" <> name
      assert Extractors.extract_atom({data, locale}, invalid_name, mapping) == nil
    end
  end

  describe "extract_atom/4 with default value" do
    test "returns default value when value has no mapping", %{
      build: build
    } do
      atom = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()
      value = Faker.String.base64(8)
      mapping = %{value => atom}

      default_value = Faker.String.base64(8)
      unmapped_value = Faker.String.base64(8)

      {name, locale, _expected_value, data} = build.(fn -> unmapped_value end)

      assert Extractors.extract_atom({data, locale}, name, mapping, default_value) ==
               default_value
    end

    test "returns default value when name is invalid", %{
      build: build
    } do
      value = Faker.String.base64(8)
      default_value = Faker.String.base64(8)
      atom = Faker.Util.format("%A%4a%A%3a") |> String.to_atom()

      mapping = %{value => atom}

      {name, locale, _expected_value, data} = build.(fn -> value end)

      invalid_name = "err_" <> name

      assert Extractors.extract_atom({data, locale}, invalid_name, mapping, default_value) ==
               default_value
    end
  end
end
