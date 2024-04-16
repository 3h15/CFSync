defmodule CFSync.EntryTest do
  use ExUnit.Case, async: true

  doctest CFSync.Entry

  alias CFSync.Entry

  import ExUnit.CaptureLog

  defmodule Page do
    import CFSync.Entry.Extractors
    @behaviour Entry.Fields

    defstruct [
      :name
    ]

    def new(data) do
      %__MODULE__{
        name: extract_binary(data, "name", "No name")
      }
    end
  end

  test "new/2 Creates a new entry with correct fields struct" do
    store = make_ref()

    content_types = %{
      "content_type_id" => %{
        content_type: :content_type_key,
        fields_module: Page
      }
    }

    data = %{
      "sys" => %{
        "id" => "ABCDEF",
        "type" => "Entry",
        "revision" => 12,
        "contentType" => %{
          "sys" => %{
            "id" => "content_type_id"
          }
        },
        "space" => %{
          "sys" => %{
            "id" => "GHIJKL"
          }
        }
      },
      "fields" => %{"name" => %{"en_US" => "A name"}}
    }

    assert %Entry{
             store: ^store,
             id: "ABCDEF",
             revision: 12,
             space_id: "GHIJKL",
             content_type: :content_type_key,
             fields: %Page{name: "A name"}
           } = Entry.new(data, content_types, {:en, "en_US"}, store)
  end

  test "It logs an error when content-type mapping is missing" do
    store = make_ref()

    data = %{
      "sys" => %{
        "id" => "ABCDEF",
        "type" => "Entry",
        "revision" => 12,
        "contentType" => %{
          "sys" => %{
            "id" => "unknown_content_type_id"
          }
        },
        "space" => %{
          "sys" => %{
            "id" => "GHIJKL"
          }
        }
      },
      "fields" => %{}
    }

    content_types = %{}

    {result, log} =
      with_log(
        [level: :error],
        fn ->
          Entry.new(data, content_types, {:en, "en_US"}, store)
        end
      )

    assert %Entry{
             content_type: :unknown,
             fields: nil
           } = result

    assert log =~ "CFSync mapping error for content type \"unknown_content_type_id\":"
    assert log =~ "No mapping provided for this content type."
  end

  test "It logs an error when content-type has invalid mapping parameters" do
    store = make_ref()

    content_types = %{
      "content_type_id" => %{
        content_type: :content_type_key,
        fields_module: "not_a_module"
      }
    }

    data = %{
      "sys" => %{
        "id" => "ABCDEF",
        "type" => "Entry",
        "revision" => 12,
        "contentType" => %{
          "sys" => %{
            "id" => "content_type_id"
          }
        },
        "space" => %{
          "sys" => %{
            "id" => "GHIJKL"
          }
        }
      },
      "fields" => %{"name" => %{"en_US" => "A name"}}
    }

    {result, log} =
      with_log(
        [level: :error],
        fn ->
          Entry.new(data, content_types, {:en, "en_US"}, store)
        end
      )

    assert %Entry{
             content_type: :unknown,
             fields: nil
           } = result

    assert log =~ "CFSync mapping error for content type \"content_type_id\":"
    assert log =~ "Invalid mapping."
  end

  test "It logs an error when module for content type is not defined" do
    store = make_ref()

    content_types = %{
      "content_type_id" => %{
        content_type: :content_type_key,
        fields_module: Module.That.Does.Not.Exist
      }
    }

    data = %{
      "sys" => %{
        "id" => "ABCDEF",
        "type" => "Entry",
        "revision" => 12,
        "contentType" => %{
          "sys" => %{
            "id" => "content_type_id"
          }
        },
        "space" => %{
          "sys" => %{
            "id" => "GHIJKL"
          }
        }
      },
      "fields" => %{"name" => %{"en_US" => "A name"}}
    }

    {result, log} =
      with_log(
        [level: :error],
        fn ->
          Entry.new(data, content_types, {:en, "en_US"}, store)
        end
      )

    assert %Entry{
             content_type: :unknown,
             fields: nil
           } = result

    assert log =~ "CFSync mapping error for content type \"content_type_id\":"
    assert log =~ "Undefined fields module: Module.That.Does.Not.Exist"
  end
end
