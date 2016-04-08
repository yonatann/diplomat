use Mix.Config

config :goth,
       json: "config/credentials.json" |> Path.expand |> File.read!
