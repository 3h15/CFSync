defmodule CFSyncTest.Fields.Star do
  alias CFSync.Entry

  import CFSync.Entry.Extractors

  @behaviour Entry.FieldsConstructor

  @enforce_keys [:name]
  defstruct [:name]

  @type t() :: %__MODULE__{name: String.t()}

  @impl true
  def new(data) do
    %__MODULE__{
      name: extract_binary(data, "name", "No name")
    }
  end
end
