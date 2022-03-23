defmodule CFSync.HTTPClient do
  @type result :: {:ok, any()}

  @type error_code :: :unauthorized | :unprocessable
  @type error :: {:error, error_code()}

  @type rate_limit :: {:rate_limited, integer()}

  @callback fetch(String.t(), String.t()) :: result | error | rate_limit
end
