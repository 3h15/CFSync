defmodule CFSync.EntryTest do
  use ExUnit.Case, async: true

  doctest CFSync.Entry

  alias CFSync.Entry
  alias CFSyncTest.Fields.Page

  import ExUnit.CaptureLog

  test "new/2 Creates a new entry with correct fields struct" do
    store = make_ref()
    locale = Faker.String.base64(2)
    content_types = CFSyncTest.Entries.mapping()
    name = Faker.String.base64()
    data = entry_payload(fields: %{"name" => %{locale => name}})

    assert %Entry{
             store: ^store,
             id: id,
             revision: revision,
             space_id: space_id,
             content_type: :page,
             fields: %Page{name: ^name}
           } = Entry.new(data, content_types, locale, store)

    assert id == data["sys"]["id"]
    assert revision == data["sys"]["revision"]
    assert space_id == data["sys"]["space"]["sys"]["id"]
  end

  test "It fetches content_type atom from config" do
    content_types = [
      {"page", :page},
      {"simplePage", :simple_page},
      {"star", :star}
    ]

    for {given, expected} <- content_types do
      store = make_ref()
      locale = Faker.String.base64(2)
      content_types = CFSyncTest.Entries.mapping()
      entry = entry_payload(content_type: given) |> Entry.new(content_types, locale, store)

      assert %Entry{content_type: ^expected} = entry
    end
  end

  test "It logs an error when content-type mapping is missing" do
    store = make_ref()
    locale = Faker.String.base64(2)
    content_types = CFSyncTest.Entries.mapping()
    content_type = "unknown-content-type-" <> Faker.String.base64()
    data = entry_payload(content_type: content_type)

    {result, log} =
      with_log(
        [level: :error],
        fn ->
          Entry.new(data, content_types, locale, store)
        end
      )

    assert %Entry{
             content_type: :unknown,
             fields: nil
           } = result

    assert log =~ "CFSync mapping error for content type \"#{content_type}\":"
    assert log =~ "No mapping provided for this content type."
  end

  test "It logs an error when content-type has invalid mapping parameters" do
    store = make_ref()
    locale = Faker.String.base64(2)
    content_types = CFSyncTest.Entries.mapping()
    content_type = "contentTypeWithInvalidConfiguration"
    # Convert content_type to atom to simulate existing atom
    _content_type_atom = content_type |> Inflex.underscore() |> String.to_atom()

    data = entry_payload(content_type: content_type)

    {result, log} =
      with_log(
        [level: :error],
        fn ->
          Entry.new(data, content_types, locale, store)
        end
      )

    assert %Entry{
             content_type: :unknown,
             fields: nil
           } = result

    assert log =~ "CFSync mapping error for content type \"#{content_type}\":"
    assert log =~ "Invalid mapping."
  end

  test "It logs an error when module for content type is not defined" do
    store = make_ref()
    locale = Faker.String.base64(2)
    content_types = CFSyncTest.Entries.mapping()
    content_type = "contentTypeWithUndefinedModule"

    data = entry_payload(content_type: content_type)

    {result, log} =
      with_log(
        [level: :error],
        fn ->
          Entry.new(data, content_types, locale, store)
        end
      )

    assert %Entry{
             content_type: :unknown,
             fields: nil
           } = result

    assert log =~ "CFSync mapping error for content type \"#{content_type}\":"
    assert log =~ "Undefined fields module: CFSyncTest.Fields.UndefinedModule"
  end

  defp entry_payload(opts) do
    id = Keyword.get(opts, :id, Faker.String.base64(10))
    space_id = Keyword.get(opts, :space_id, Faker.String.base64(10))
    revision = Keyword.get(opts, :revision, Faker.random_between(1, 1000))
    content_type = Keyword.get(opts, :content_type, "page")
    fields = Keyword.get(opts, :fields, %{})

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
    }
  end
end
