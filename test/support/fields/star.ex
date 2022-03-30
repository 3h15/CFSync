defmodule CFSyncTest.Fields.Star do
  @moduledoc false

  alias CFSync.Entry

  import CFSync.Entry.Extractors
  @behaviour Entry.Fields

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
