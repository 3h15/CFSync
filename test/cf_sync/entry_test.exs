defmodule CFSync.EntryTest do
  use ExUnit.Case, async: true

  doctest CFSync.Entry

  alias CFSync.Entry
  alias CFSyncTest.Fields.Page
  alias CFSyncTest.Fields.SimplePage

  import ExUnit.CaptureLog
  import CFSyncTest.Data

  test "new/1 Creates a new entry with correct fields struct" do
    data = entry_payload()

    assert %Entry{
             id: id,
             revision: revision,
             content_type: :page,
             fields: %Page{name: name}
           } = Entry.new(data)

    assert id == data["sys"]["id"]
    assert revision == data["sys"]["revision"]
    assert name == data["fields"]["name"]
  end

  test "get_name/1 returns name provided by entry's fields module" do
    data = entry_payload()
    entry = Entry.new(data)
    assert Entry.get_name(entry) == "Page #{data["fields"]["name"]}"
  end

  test "It parses content-type to snake case atom" do
    content_types = [
      "SimplePage",
      "simplePage",
      "SIMPLE_PAGE",
      "simple_page",
      "Simple_Page",
      "simple_Page",
      "SIMPLE-PAGE",
      "simple-page",
      "Simple-Page",
      "simple-Page"
    ]

    for content_type <- content_types do
      entry = entry_payload(content_type: content_type) |> Entry.new()

      assert %Entry{
               content_type: :simple_page,
               fields: %SimplePage{}
             } = entry
    end
  end

  test "It logs an error when content-type has no corresponding local atom" do
    content_type = "unknown-content-type-" <> Faker.String.base64()
    data = entry_payload(content_type: content_type)

    {result, log} =
      with_log(
        [level: :error],
        fn ->
          Entry.new(data)
        end
      )

    assert %Entry{
             content_type: :unknown,
             fields: nil
           } = result

    assert log =~ "Unknown entry content_type: #{inspect(content_type)}"
  end

  test "It logs an error when content-type has no configured module" do
    content_type = "unknown-content-type-" <> Faker.String.base64()
    # Convert content_type to atom to simulate existing atom
    content_type_atom = content_type |> Inflex.underscore() |> String.to_atom()

    data = entry_payload(content_type: content_type)

    {result, log} =
      with_log(
        [level: :error],
        fn ->
          Entry.new(data)
        end
      )

    assert %Entry{
             content_type: content_type_atom,
             fields: nil
           } = result

    assert log =~ "No configured fields module for content_type: #{inspect(content_type_atom)}"
  end

  test "It logs an error when module for content-type is not defined" do
    content_type = "content_type_with_undefined_module"

    data = entry_payload(content_type: content_type)

    {result, log} =
      with_log(
        [level: :error],
        fn ->
          Entry.new(data)
        end
      )

    assert %Entry{
             content_type: :content_type_with_undefined_module,
             fields: nil
           } = result

    assert log =~ "Undefined module: CFSyncTest.Fields.UndefinedModule"
  end
end
