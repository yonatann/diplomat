use Mix.Config

try do
  config :goth,
         json: "config/credentials.json" |> Path.expand |> File.read!
rescue
  _ -> :ok
end
