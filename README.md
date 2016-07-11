# Diplomat

Diplomat is an Elixir library for interacting with Google's Cloud Datastore.

## Installation

  1. Add datastore to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:diplomat, "~> 0.0.5"}]
  end
  ```

  2. Make sure you've configured [https://github.com/peburrows/goth](Goth) with your credentials:

  ```elixir
  config :goth,
    json: "path/to/google/json/creds.json" |> File.read!
  ```

## Usage

#### Insert an Entity:

```elixir
Diplomat.Entity.new(
  %{"name" => "My awesome book", "author" => "Phil Burrows"},
  "Book",
  "my-unique-book-id"
) |> Diplomat.Entity.insert
```

#### Find an Entity via a GQL Query:

```elixir
Diplomat.Query.new(
  "select * from `Book` where name = @name",
  %{name: "20,000 Leagues Under The Sea"}
) |> Diplomat.Query.execute
```
