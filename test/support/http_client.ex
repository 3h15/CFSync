defmodule CFSync.HTTPClientMock do
  @callback fetch(CFSync.Space.t(), nil | String.t()) :: any()
end
