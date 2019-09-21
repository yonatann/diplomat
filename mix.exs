defmodule Diplomat.Mixfile do
  use Mix.Project

  def project do
    [app: :diplomat,
     version: "0.8.2",
     elixir: "~> 1.3",
     description: "A library for interacting with Google's Cloud Datastore",
     package: package(),
     deps: deps(),
     dialyzer: [ignore_warnings: ".dialyzer.ignore-warnings"]]
  end

  def application do
    [applications: [:logger, :goth, :exprotobuf, :httpoison]]
  end

  defp deps do
    [
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:goth, "~> 1.0"},
      {:exprotobuf, "~> 1.2"},
      {:httpoison, "~> 1.0"},
      {:poison, "~> 2.2 or ~> 3.1"},
      {:bypass, "~> 0.8", only: :test},
      {:mix_test_watch, "~> 0.4", only: :dev},
      {:ex_doc, "~> 0.16", only: :dev},
      {:earmark, "~> 1.2", only: :dev},
      {:uuid, "~> 1.1", only: :test},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
    ]
  end

  defp package do
    [
      maintainers: ["Phil Burrows"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/peburrows/diplomat"}
    ]
  end
end
