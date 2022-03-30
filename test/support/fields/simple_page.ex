defmodule CFSyncTest.Fields.SimplePage do
  @moduledoc false

  alias CFSync.Entry

  @behaviour Entry.Fields

  @enforce_keys [:name]
  defstruct [:name]

  @type t() :: %__MODULE__{name: String.t()}

  @impl true
  def new({fields_payload, _locale}) do
    name = Map.get(fields_payload, "name", "Some name")
    %__MODULE__{name: name}
  end
end
