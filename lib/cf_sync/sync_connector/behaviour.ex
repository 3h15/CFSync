defmodule CFSync.SyncConnector.Behaviour do
  alias CFSync.SyncPayload

  @callback sync(CFSync.Space.t(), String.t(), nil | String.t()) ::
              {:ok, SyncPayload.t()} | {:rate_limited, integer()} | {:error, binary()}
end
