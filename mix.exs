defmodule Diplomat.Mixfile do
  use Mix.Project

  def project do
    [app: :diplomat,
     version: "0.1.0-rc.2",
     elixir: ">= 1.3.0",
     description: "A library for interacting with Google's Cloud Datastore",
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger, :goth, :exprotobuf, :httpoison]]
  end

  defp deps do
    [
      {:goth, "~> 0.1.4"},
      {:exprotobuf, "~> 1.0.1"},
      {:httpoison, "~> 0.8.0"},
      {:poison, "~> 2.1"},
      {:bypass, "~> 0.1", only: :test},
      {:mix_test_watch, "~> 0.2.5", only: :dev},
      {:ex_doc, "~> 0.13.0", only: :dev},
      {:earmark, "~> 1.0", only: :dev},
      {:uuid, "~> 1.1", only: :test},
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
