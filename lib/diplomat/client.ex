defmodule Diplomat.Client do
  alias Diplomat.Proto.{Key, Key.PathElement, AllocateIdsRequest}

  @api_scope "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/datastore"

  # we'll deal with ancestors later, but the gist is this: pass a from parent to child, ie:
  # [%{kind: "Book", name: "20KLeagues"}, %{kind: "Author", name: "Jules Verne"}]
  # def allocate_ids(kind, num \\ 1) when num > 0 do
  #   keys = 0..(num-1) |> Enum.map(fn(_i)->
  #     # "The path element must not be complete" i.e. it can only have a kind at its deepest level
  #     Key.new(path_element: [PathElement.new(kind: kind)])
  #   end)
  #
  #   req = AllocateIdsRequest.new(key: keys)
  #
  #   {:ok, resp} = HTTPoison.post("https://www.googleapis.com/datastore/v1beta2/datasets/vitalsource-gc/allocateIds",
  #                                 AllocateIdsRequest.encode(req),
  #                                 [auth_header, proto_header])
  #
  #   IO.inspect resp.body
  #   id_resp = Diplomat.Proto.AllocateIdsResponse.decode(resp.body)
  #   id_resp.key |> List.first
  # end

  # def save(key, %{}=val) do
  #   # entity = Diplomat.Entity.new(Key.new(path_element: [PathElement.new(kind: key)]), val)
  #   entity = Diplomat.Entity.proto(allocate_ids(key), val)
  #
  #   # props = Enum.map(val, fn({name, val})->
  #   #   # Diplomat.Proto.Property.new(name: name, value: Diplomat.Value.new(val))
  #   #   Diplomat.Property.new(name: name, value: val)
  #   # end)
  #   # entity   = Diplomat.Proto.Entity.new(key: ), property: props)
  #   mutation = Diplomat.Proto.Mutation.new(insert: [entity])
  #   commit   = Diplomat.Proto.CommitRequest.new(mutation: mutation, mode: :NON_TRANSACTIONAL)
  #   {:ok, resp} = HTTPoison.post("https://www.googleapis.com/datastore/v1beta2/datasets/vitalsource-gc/commit",
  #                   Diplomat.Proto.CommitRequest.encode(commit),
  #                   [auth_header, proto_header])
  #
  #   IO.inspect resp.body
  #   Diplomat.Proto.CommitResponse.decode(resp.body)
  #     |> IO.inspect
  # end

  def allocate_ids(req) do
    req
    |> Diplomat.Proto.AllocateIdsRequest.encode
    |> call("allocate")
  end

  defp call(data, path) do
    {:ok, project} = Goth.Config.get(:project_id)
    Path.join([endpoint, "datasets", project, path])
    |> HTTPoison.post(data, [auth_header, proto_header])
    |> case do
      {:ok, response} -> {:ok, response.body}
      other           -> other
    end
  end

  defp endpoint, do: Application.get_env(:diplomat, :endpoint, "https://www.googleapis.com/datastore/v1beta2")

  defp auth_header do
    {:ok, token} = Goth.Token.for_scope(@api_scope)
    {"Authorization", "#{token.type} #{token.token}"}
  end

  defp proto_header do
    {"Content-Type", "application/x-protobuf"}
  end
end
