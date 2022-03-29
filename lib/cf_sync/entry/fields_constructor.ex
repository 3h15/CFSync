defmodule CFSync.Entry.FieldsConstructor do
  @moduledoc false

  @callback new({map, binary}) :: CFSync.Entry.Fields.t()
end
