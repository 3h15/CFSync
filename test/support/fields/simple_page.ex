defmodule CFSyncTest.Fields.SimplePage do
  alias CFSync.Entry

  @behaviour Entry.FieldsConstructor

  @enforce_keys [:name]
  defstruct [:name]

  @type t() :: %__MODULE__{name: String.t()}

  @impl true
  def new(fields_payload, _lang) do
    name = Map.get(fields_payload, "name", "Some name")
    %__MODULE__{name: name}
  end

  defimpl Entry.Fields do
    @spec get_name(CFSyncTest.Fields.Page.t()) :: binary()
    def get_name(this) do
      "Simple page #{this.name}"
    end
  end
end