defmodule CFSyncTest.Fields.Page do
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

  defimpl Entry.Fields do
    @spec get_name(CFSyncTest.Fields.Page.t()) :: binary()
    def get_name(this) do
      "Page #{this.name}"
    end
  end
end
