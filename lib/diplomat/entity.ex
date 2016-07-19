defmodule Diplomat.Entity do
  alias Diplomat.Proto.Entity, as: PbEntity
  alias Diplomat.Proto.{CommitRequest, Mutation}
  alias Diplomat.{Key, Value, Entity}

  defstruct kind: nil, key: nil, properties: %{}

  def new(%{}=props) do
    %Entity{properties: value_properties(props)}
  end
  def new(%{}=props, kind \\ nil, id \\ nil) do
    %Entity{
      kind: kind,
      key: Key.new(kind, id),
      properties: value_properties(props)
    }
  end

  defp value_properties(%{} = props) do
    props
    |> Map.to_list
    |> Enum.map(fn {name, value} -> {name, Value.new(value)} end)
    |> Enum.into(%{})
  end

  def proto(%Entity{key: key, properties: properties}) do
    pb_properties =
      properties
      |> Map.to_list
      |> Enum.map(fn {name, value} ->
        {name, Value.proto(value)}
      end)

    %PbEntity{
      key: key |> Key.proto,
      properties: pb_properties
    }
  end
  def proto(%{} = properties) do
    proto(%Entity{key: nil, properties: properties})
  end

  def from_proto(%PbEntity{key: pb_key, properties: pb_properties}) do
    properties =
      pb_properties
      |> Enum.map(fn {name, pb_value} ->
        {name, Value.from_proto(pb_value)}
      end)
      |> Enum.into(%{})
    key = Key.from_proto(pb_key)
    %Entity{
      kind: if key do key.kind else nil end,
      key: key,
      properties: properties
    }
  end

  def properties(%Entity{properties: properties}) do
    properties
    |> Enum.map(fn {key, %Value{value: value}} ->
      case value do
        %Entity{} -> {key, value |> properties}
        _ -> {key, value}
      end
    end)
    |> Enum.into(%{})
  end

  def insert(%Entity{}=entity), do: insert([entity])
  def insert(entities) when is_list(entities) do
    [insert: proto_list(entities, [])]
    |> commit_request
    |> Diplomat.Client.commit
    |> case do
      {:ok, resp} -> Key.from_commit_proto(resp)
      any -> any
    end
  end

  # at some point we should validate the entity keys
  def upsert(%Entity{}=entity), do: upsert([entity])
  def upsert(entities) when is_list(entities) do
    [upsert: proto_list(entities, [])]
    |> commit_request
    |> Diplomat.Client.commit
    |> case do
         {:ok, resp} -> resp
         any -> any
    end
  end

  defp proto_list([], acc), do: Enum.reverse(acc)
  defp proto_list([e|tail], acc) do
    proto_list(tail, [Entity.proto(e) | acc])
  end

  defp commit_request(opts, mode \\ :NON_TRANSACTIONAL) do
    CommitRequest.new(
      mode: mode,
      mutation: Mutation.new(opts)
    )
  end
end
