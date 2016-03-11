defmodule Datastore.Client do
  alias Datastore.Proto.{Key, Key.PathElement, AllocateIdsRequest}

  @api_scope "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/datastore"

  # we'll deal with ancestors later, but the gist is this: pass a from parent to child, ie:
  # [%{kind: "Book", name: "20KLeagues"}, %{kind: "Author", name: "Jules Verne"}]
  def allocate_ids(kind, num \\ 1) when num > 0 do
    keys = 0..(num-1) |> Enum.map(fn(_i)->
      # "The path element must not be complete" i.e. it can only have a kind at its deepest level
      Key.new(path_element: [PathElement.new(kind: kind)])
    end)

    req = AllocateIdsRequest.new(key: keys)

    {:ok, resp} = HTTPoison.post("https://www.googleapis.com/datastore/v1beta2/datasets/vitalsource-gc/allocateIds",
                                  AllocateIdsRequest.encode(req),
                                  [auth_header, proto_header])

    IO.inspect resp.body
    Datastore.Proto.AllocateIdsResponse.decode(resp.body)
      |> IO.inspect
  end

  def save(key, %{}=val) do
    props = Enum.map(val, fn({name, val})->
      # Datastore.Proto.Property.new(name: name, value: Datastore.Value.new(val))
      Datastore.Property.new(name: name, value: val)
    end)
    entity   = Datastore.Proto.Entity.new(key: Key.new(path_element: [PathElement.new(kind: key)]), property: props)
    mutation = Datastore.Proto.Mutation.new(upsert: [entity])

    IO.inspect(mutation)
    mutation
  end

  defp auth_header do
    {:ok, token} = Goth.Token.for_scope(@api_scope)
    {"Authorization", "#{token.type} #{token.token}"}
  end

  defp proto_header do
    {"Content-Type", "application/x-protobuf"}
  end
end