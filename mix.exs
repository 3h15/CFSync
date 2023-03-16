defmodule CFSync.MixProject do
  use Mix.Project

  def project do
    [
      app: :cf_sync,
      version: "0.11.0",
      elixir: "~> 1.13",
      name: "CFSync",
      description: description(),
      package: package(),
      source_url: "https://github.com/3h15/CFSync",
      docs: [
        main: "CFSync"
      ],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14.4", only: :test},
      {:faker, "~> 0.17", only: :test},
      {:httpoison, "~> 1.7"},
      {:inflex, "~> 2.1"},
      {:jason, "~> 1.2"},
      {:mox, "~> 1.0", only: :test},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_view, "~> 0.18.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp description() do
    """
    Contentful sync API client for Elixir.
    """
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "cf_sync",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/3h15/CFSync"}
    ]
  end
end
