defmodule CFSync.Entry.FieldsConstructor do
  @moduledoc false

  @callback new(map()) :: CFSync.Entry.Fields.t()
end
