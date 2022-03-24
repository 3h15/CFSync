defmodule CFSyncTest.Data do
  def entry_payload(opts \\ []) do
    id = Keyword.get(opts, :id, Faker.String.base64(10))
    revision = Keyword.get(opts, :revision, Faker.random_between(1, 1000))
    content_type = Keyword.get(opts, :content_type, "page")

    fields =
      case Keyword.get(opts, :fields) do
        nil ->
          fields_payload(:custom)

        content_type when is_atom(content_type) ->
          fields_payload(content_type)

        {content_type, opts} when is_atom(content_type) and is_list(opts) ->
          fields_payload(content_type, opts)
      end

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
    }
  end

  def fields_payload(:custom, fields \\ %{"name" => "My Name"}) do
    for {k, v} <- fields, into: %{} do
      {k, v}
    end
  end
end
