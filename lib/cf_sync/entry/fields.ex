defprotocol CFSync.Entry.Fields do
  @moduledoc false

  @spec get_name(t) :: binary()
  def get_name(fields)
end
