defmodule CFSyncTest.HTTPoisonBehaviour do
  @moduledoc false

  @callback request(HTTPoison.Request.t()) :: any()
end
