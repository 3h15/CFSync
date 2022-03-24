defmodule CFSync.Space do
  @enforce_keys [:root_url, :space_id, :token]
  defstruct [:root_url, :space_id, :token]

  @type t :: %__MODULE__{root_url: String.t(), space_id: String.t(), token: String.t()}

  @spec new(String.t(), String.t(), String.t()) :: %__MODULE__{}

  def new(url, space_id, token) do
    %__MODULE__{
      root_url: url,
      space_id: space_id,
      token: token
    }
  end
end
