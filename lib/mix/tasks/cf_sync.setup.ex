defmodule Mix.Tasks.CfSync.Setup do
  @moduledoc """
  This task builds config files for use with `mix cf_sync.dump`.
  """
  @shortdoc "Setup configuration for `mix cf_sync.dump`."

  use Mix.Task

  import CfSync.Tasks.Utils

  @default_url "https://cdn.contentful.com/"

  @impl Mix.Task
  def run(_) do
    name =
      ask("Config name: (default) ",
        filter: ~r/^[a-z_]+$/,
        error_message: "Lowercase and underscore only, please.",
        default_value: "default"
      )

    next =
      case read_conf(name) do
        :no_file ->
          :setup

        {:ok, data} ->
          warn("Current config data for \"#{name}\":")
          IO.puts("########## START CONFIG ##########")
          IO.puts(inspect(data, pretty: true, width: 0))
          IO.puts("########### END CONFIG ###########")

          overwrite =
            ask("Do you want to overwrite this config file? ",
              default_value: "n"
            )

          if String.downcase(overwrite) == "y" do
            :setup
          else
            :end
          end
      end

    if next == :setup, do: setup(name)
  end

  defp setup(name) do
    root_url =
      ask(
        "Content delivery API root: (#{@default_url}) ",
        filter:
          ~r/^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$/,
        default_value: @default_url,
        error_msg: "URL format, please."
      )

    space_id = ask("Contentful space ID: ", filter: ~r/^.+$/)
    delivery_token = ask("Token for Content delivery API: ", filter: ~r/^.+$/)

    write_conf!(name, %{
      root_url: root_url,
      space_id: space_id,
      delivery_token: delivery_token
    })
  end
end
