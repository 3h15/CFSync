defmodule CFSync.HTTPoisonBehaviour do
  @callback request(HTTPoison.Request.t()) :: any()
end