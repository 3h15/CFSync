defmodule CFSync.Store.Table do
  def new(name) when is_atom(name) do
    :ets.new(name, [
      :named_table,
      :set,
      :protected,
      write_concurrency: false,
      read_concurrency: true
    ])

    :ets.whereis(name)
  end
end
