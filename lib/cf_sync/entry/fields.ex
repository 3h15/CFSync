defmodule CFSync.Entry.Fields do
  @moduledoc """
  behaviour for fields struct.

  For each Contentful content-type you want to map in your Elixir app,
  you have to provide an Elixir module implementing this behaviour.
  """

  @type t() :: struct()

  @doc """
  Called at struct creation.

  When creating an entry, CFSync will call this function with entry's data as
  first argument. Your implementation must return a struct implementing the
  `CFSync.Entry.Fields` protocol.

  The struct must be build using the `extract_*` functions provided by
  `CFSync.Entry.Extractors`

  You must configure your fields struct in config.exs, see `CFSync`.

  ## Example
  ```
  defmodule MyApp.PageFields do
    alias CFSync.Entry

    @behaviour Entry.Fields
    import Entry.Extractors

    defstruct :name, :body, :author

    def new(data) do
      %__MODULE__{
        # field_name: extract_*(data, "fieldNameInContentful", default: default_value)
        name: extract_binary(data, "name", default: "Default name"),
        body: extract_richtext(data, "body"),
        author: extract_link(data, "author"),
      }
    end
  end
  ```
  """
  @callback new(CFSync.Entry.Extractors.data()) :: __MODULE__.t()
end
