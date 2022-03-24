defmodule CFSyncTest.Fields.Page do
  alias CFSync.Entry

  @behaviour Entry.FieldsConstructor

  @enforce_keys [:name]
  defstruct [:name]

  @type t() :: %__MODULE__{name: String.t()}

  @impl true
  def new(%{"name" => name}) do
    %__MODULE__{name: name}
  end

  defimpl Entry.Fields do
    @spec get_name(CFSyncTest.Fields.Page.t()) :: binary()
    def get_name(this) do
      "Page #{this.name}"
    end
  end
end
