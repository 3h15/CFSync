defmodule CfSync.Tasks.Utils do
  @moduledoc false

  @main_dir_name ".cf_sync/"
  @conf_dir_name "conf/"
  @dump_dir_name "dump/"
  @file_extension ".etf"

  def ask(msg, opts \\ []) do
    default_value = Keyword.get(opts, :default_value)
    filter = Keyword.get(opts, :filter, ~r/.*/)
    error_msg = Keyword.get(opts, :error_msg)

    value =
      IO.gets("#{msg}")
      |> String.trim()

    if value == "" and default_value != nil do
      default_value
    else
      if test_value(value, filter) do
        value
      else
        if error_msg, do: warn(error_msg)
        ask(msg, opts)
      end
    end
  end

  defp test_value(value, filter) when is_list(filter) do
    value in filter
  end

  defp test_value(value, %Regex{} = filter) do
    value =~ filter
  end

  def warn(msg) do
    IO.puts(IO.ANSI.format([:yellow, msg]))
  end

  def write_conf!(name, data), do: write!(:conf, name, data)
  def read_conf(name), do: read(:conf, name)

  def write_dump!(name, data), do: write!(:dump, name, data)
  def read_dump(name), do: read(:dump, name)

  defp write!(type, name, data) do
    type
    |> file(name)
    |> File.write!(:erlang.term_to_iovec(data))
  end

  defp read(type, name) do
    result =
      type
      |> file(name)
      |> File.read()

    case result do
      {:ok, data} ->
        {:ok, :erlang.binary_to_term(data)}

      {:error, :enoent} ->
        :no_file

      _ ->
        raise "Unable to read file"
    end
  end

  defp file(type, name) do
    Path.join(dir(type), name <> @file_extension)
  end

  defp dir(type) do
    dir_name =
      case type do
        :conf -> @conf_dir_name
        :dump -> @dump_dir_name
      end

    dir = Path.join(root(), dir_name)
    File.mkdir(dir)
    dir
  end

  defp root() do
    dir = Path.join(File.cwd!(), @main_dir_name)
    File.mkdir(dir)
    dir
  end
end
