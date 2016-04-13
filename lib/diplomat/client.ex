defmodule Diplomat.Client do
  alias Diplomat.Proto.{Key, Key.PathElement, AllocateIdsRequest}

  @api_scope "https://www.googleapis.com/auth/datastore"

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
    |> call("allocateIds")
    |> case do
      {:ok, body} ->
        body
        |> Diplomat.Proto.AllocateIdsResponse.decode
        |> Diplomat.Key.from_allocate_ids_proto
      any -> any
    end
  end

  def commit(req) do
    req
    |> Diplomat.Proto.CommitRequest.encode
    |> call("commit")
    |> case do
      {:ok, body} ->
        IO.puts "the response: #{inspect body}"
        decoded = Diplomat.Proto.CommitResponse.decode(body)
        {:ok, decoded}
      any ->
        IO.puts "nope: #{inspect any}"
        any
    end
  end

  defp call(data, path) do
    {:ok, project} = Goth.Config.get(:project_id)
    Path.join([endpoint, api_version, "projects", "#{project}:#{path}"])
    |> HTTPoison.post(data, [auth_header, proto_header])
    |> case do
      {:ok, response} ->
        IO.puts "the response code: #{response.status_code}"
        {:ok, response.body}
      other           -> other
    end
  end

  defp api_version, do: "v1beta3"
  defp endpoint, do: Application.get_env(:diplomat, :endpoint, "https://datastore.googleapis.com")
  defp token_module, do: Application.get_env(:diplomat, :token_module, Goth.Token)

  defp auth_header do
    {:ok, token} = token_module.for_scope(@api_scope)
    {"Authorization", "#{token.type} #{token.token}"}
  end

  defp proto_header do
    {"Content-Type", "application/x-protobuf"}
  end
end
