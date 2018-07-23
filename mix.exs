defmodule KCAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :kc_auth,
      version: "0.1.2",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [
        plt_add_deps: :transitive,
        plt_add_apps: [:mix],
        flags: [:race_conditions, :no_opaque]
      ]
    ]
  end

  def application do
    [applications: [:cachex, :httpoison, :jason, :jose, :plug, :parse_trans, :unsafe]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:httpoison, "~> 1.0"},
      {:jason, "~> 1.1"},
      {:jose, "~> 1.8"},
      {:cachex, "~> 3.0"},
      {:plug, "~> 1.6"},

      # Dev/Test dependencies
      {:exvcr, "~> 0.10", only: :test},
      {:mix_test_watch, "~> 0.5", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test, runtime: false},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
    ]
  end
end
