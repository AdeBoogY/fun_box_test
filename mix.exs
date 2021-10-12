defmodule FunBox.MixProject do
  use Mix.Project

  def project do
    [
      app: :fun_box,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :cowboy, :plug, :poison],
      mod: {FunBox.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
        {:plug_cowboy, git: "https://github.com/elixir-plug/plug_cowboy.git", branch: "master"},
        {:cowboy, "~> 2.7"},
        {:plug, "~> 1.5"},
        {:poison, "~> 3.1"},
        {:redix, "~> 1.1"},
        {:castore, ">= 0.0.0"}
    ]
  end
end
