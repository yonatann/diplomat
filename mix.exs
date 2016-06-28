defmodule Diplomat.Mixfile do
  use Mix.Project

  def project do
    [app: :diplomat,
     version: "0.0.5",
     elixir: ">= 1.2.5",
     description: "A library for interacting with Google's Cloud Datastore",
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger, :goth, :exprotobuf, :httpoison, :timex]]
  end

  defp deps do
    [
      {:goth, "~> 0.1.1"},
      {:exprotobuf, git: "https://github.com/kiennt/exprotobuf"},
      {:httpoison, "~> 0.8.0"},
      {:poison, "~> 2.1"},
      # {:chatterbox, github: "joedevivo/chatterbox"},
      {:timex, "~> 2.2.1"},
      {:bypass, "~> 0.1", only: :test},
      {:mix_test_watch, "~> 0.2.5", only: :dev},
      {:ex_doc, ">= 0.0.0", only: [:dev]},
      {:earmark, ">= 0.0.0"},
      {:uuid, "~> 1.1", only: :test}
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
