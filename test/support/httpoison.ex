defmodule CFSync.HTTPoisonMock do
  @callback request(String.t()) :: any()
end
