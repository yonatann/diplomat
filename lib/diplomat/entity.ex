defmodule Diplomat.Entity do
  alias Diplomat.Proto.Entity, as: PbEntity
  alias Diplomat.Proto.{CommitRequest, Mutation}
  alias Diplomat.{PropertyList, Key, Entity}

  defstruct kind: nil, key: nil, properties: []

  def new(%{}=props, kind \\ nil, id \\ nil) do
    %Entity{
      kind: kind,
      key: Key.new(kind, id),
      properties: PropertyList.new(props)
    }
  end

  def add_property(%Entity{}=entity, %Diplomat.Property{}=prop) do
    %{entity | properties: [prop|entity.properties]}
  end

  def proto(%Entity{key: nil, properties: val}),
    do: proto(val)
  def proto(%Entity{key: key, properties: val}),
    do: proto(key, val)

  def proto(val),
    do: PbEntity.new(property: PropertyList.proto(val))

  def proto(%Diplomat.Proto.Key{}=key, val) do
    PbEntity.new(key:      key,
                 property: PropertyList.proto(val) )
  end

  def proto(%Key{}=key, val) do
    proto(Key.proto(key), val)
  end

  def from_proto(%PbEntity{property: val, key: key}) do
    %__MODULE__{
      key: Key.from_proto(key),
      properties: PropertyList.from_proto(val)
    }
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
