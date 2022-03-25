defmodule CFSync.SyncConnector.Behaviour do
  @callback sync(CFSync.Space.t(), nil | String.t()) :: any()
end
