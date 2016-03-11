# Datastore

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add datastore to your list of dependencies in `mix.exs`:

        def deps do
          [{:datastore, "~> 0.0.1"}]
        end

  2. Ensure datastore is started before your application:

        def application do
          [applications: [:datastore]]
        end


## Eventual Usage

```elixir
Datastore.allocateIds("Book", 3)
```

So allocating IDs looks something like:

* generate n %Datastore.Protobuf.Key object(s)
* generate a %Datastore.Protobuf.AllocateIdsRequest with %{keys: [%Datastore.Protobuf.Keys{}]}
* POST to the endpoint
* parse the response and generage a %Datastore.Protobug.AllocateIdsResponse object
* return the Key objects from that Response...?
