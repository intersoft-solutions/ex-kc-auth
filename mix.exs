defmodule KCAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :kc_auth,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [applications: [:cachex, :httpoison]]
  end

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
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
    ]
  end
end
