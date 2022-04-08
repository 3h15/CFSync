defmodule CFSyncTest.Entries do
  @moduledoc false

  def mapping,
    do: %{
      "page" => %{
        content_type: :page,
        fields_module: CFSyncTest.Fields.Page
      },
      "simplePage" => %{
        content_type: :simple_page,
        fields_module: CFSyncTest.Fields.SimplePage
      },
      "star" => %{
        content_type: :star,
        fields_module: CFSyncTest.Fields.Star
      },
      "contentTypeWithUndefinedModule" => %{
        content_type: :content_type_with_undefined_module,
        fields_module: CFSyncTest.Fields.UndefinedModule
      },
      "contentTypeWithInvalidConfiguration" => %{
        content_type: "bad",
        fields_module: 6
      }
    }
end
