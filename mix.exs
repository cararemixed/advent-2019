defmodule Advent.MixProject do
  use Mix.Project

  def project do
    [
      app: :advent,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: [
        {:dialyzex, ">=0.0.0"}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end
