# Diplomat

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add datastore to your list of dependencies in `mix.exs`:

        def deps do
          [{:diplomat, "~> 0.0.1"}]
        end

  2. Ensure datastore is started before your application:

        def application do
          [applications: [:diplomat]]
        end


## Eventual Usage

```elixir
Diplomat.allocateIds("Book", 3)
```

So allocating IDs looks something like:

* generate n %Diplomat.Protobuf.Key object(s)
* generate a %Diplomat.Protobuf.AllocateIdsRequest with %{keys: [%Diplomat.Protobuf.Keys{}]}
* POST to the endpoint
* parse the response and generage a %Diplomat.Protobug.AllocateIdsResponse object
* return the Key objects from that Response...?
