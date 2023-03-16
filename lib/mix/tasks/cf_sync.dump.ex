defmodule Mix.Tasks.CfSync.Dump do
  @moduledoc """
  This task downloads the contentful entries and assets to a local file for dev purposes.
  """
  @shortdoc "Dump CF data to .cf_sync/"

  use Mix.Task

  import CfSync.Tasks.Utils

  @impl Mix.Task
  def run(_args) do
    name =
      ask("Config name: (default) ",
        filter: ~r/^[a-z_]+$/,
        error_message: "Lowercase and underscore only, please.",
        default_value: "default"
      )

    case read_conf(name) do
      :no_file ->
        warn("No config data for \"#{name}\". Use Mix cf_sync.setup to create it.")

      {:ok, config} ->
        dump(name, config)
    end
  end

  def dump(name, config) do
    data = fetch_all(config)
    write_dump!(name, data)
  end

  def fetch_all(config) do
    HTTPoison.start()
    IO.puts("\n\nDownloading data...")

    url = initial_url(config.root_url, config.space_id)

    pages =
      fetch(url, config.delivery_token)
      |> Stream.iterate(&fetch_next(&1, config.delivery_token))
      |> Stream.take_while(&(&1 != nil))
      |> Stream.each(fn _ -> IO.write(".") end)
      |> Enum.to_list()

    IO.puts("\nDownloaded #{length(pages)} files.")

    pages
  end

  defp fetch_next(url, token) when is_binary(url),
    do: fetch(url, token)

  defp fetch_next(%{"nextPageUrl" => url}, token) when is_binary(url),
    do: fetch_next(url, token)

  defp fetch_next(_url, _token),
    do: nil

  defp fetch(url, token, attempts \\ 1)

  defp fetch(_url, _token, attempts) when attempts > 9 do
    raise "Unable to fetch data from Contentful"
  end

  defp fetch(url, token, attempts) do
    case CFSync.HTTPClient.HTTPoison.fetch(url, token) do
      {:ok, data} ->
        data

      {:rate_limited, delay} ->
        IO.puts("Rate limited...")
        Process.sleep(delay + 1000)
        fetch(url, token, attempts + 1)
    end
  end

  defp initial_url(root_url, space_id), do: "#{root_url}spaces/#{space_id}/sync/?initial=true"
end
