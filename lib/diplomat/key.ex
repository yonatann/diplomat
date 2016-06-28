defmodule Diplomat.Key do
  alias Diplomat.Key
  alias Diplomat.Proto.Key, as: PbKey
  alias Diplomat.Proto.Key.PathElement, as: PbPathElement
  alias Diplomat.Proto.PartitionId, as: PbPartition
  alias Diplomat.Proto.{MutationResult, CommitResponse, LookupRequest}

  defstruct id: nil, name: nil, kind: nil, parent: nil, project_id: nil, namespace: nil

  def new(kind),
    do: %__MODULE__{kind: kind}
  def new(kind, id) when is_integer(id),
    do: %__MODULE__{kind: kind, id: id}
  def new(kind, name),
    do: %__MODULE__{kind: kind, name: name}

  def new(kind, id_or_name, %__MODULE__{}=parent),
    do: %{new(kind, id_or_name) | parent: parent}

  def from_path([[kind, id]|tail]),
    do: from_path(tail, new(kind, id))
  def from_path([_, _]=path),
    do: from_path([path])

  defp from_path([], parent),
    do: parent
  defp from_path([[kind, id]|tail], parent),
    do: from_path(tail, new(kind, id, parent))

  def proto(nil) do
    nil
  end
  def proto(%__MODULE__{}=key) do
    path_els = key
    |> path
    |> proto([])
    |> Enum.reverse

    partition = case (key.project_id || key.namespace) do
      nil -> nil
      _   -> PbPartition.new(project_id: key.project_id, namespace: key.namespace)
    end

    PbKey.new(partition_id: partition, path: path_els)
  end

  defp proto([], acc), do: acc
  defp proto([[kind, id]|tail], acc) when is_integer(id) do
    proto(tail, [PbPathElement.new(kind: kind, id_type: {:id, id})|acc])
  end
  defp proto([[kind, name]|tail], acc) do
    proto(tail, [PbPathElement.new(kind: kind, id_type: {:name, name})|acc])
  end

  def from_proto(nil), do: nil
  def from_proto(%PbKey{partition_id: nil, path: path_el}),
    do: from_path_proto(path_el, [])
  def from_proto(%PbKey{partition_id: %PbPartition{project_id: pid, namespace_id: ns}, path: path_el}),
    do: %{from_path_proto(path_el, []) | project_id: pid, namespace: ns}

  defp from_path_proto([], acc) do
    acc |> Enum.reverse |> from_path
  end
  defp from_path_proto([head|tail], acc) do
    case head.id_type do
      {:id, id} -> from_path_proto(tail, [[head.kind, id]|acc])
      # in case value return as char list
      {:name, name} -> from_path_proto(tail, [[head.kind, to_string(name)]|acc])
    end
  end

  def path(key) do
    key
    |> ancestors_and_self([])
    |> generate_path([])
  end

  # I hate the way this method looks
  def from_commit_proto(%CommitResponse{mutation_results: results}) do
    results
    |> Enum.map(&Key.from_proto(&1.key))
  end

  def incomplete?(%__MODULE__{id: nil, name: nil}), do: true
  def incomplete?(%__MODULE__{}), do: false
  def complete?(%__MODULE__{}=k), do: !incomplete?(k)

  defp ancestors_and_self(nil, acc), do: Enum.reverse(acc)
  defp ancestors_and_self(key, acc) do
    ancestors_and_self(key.parent, [key|acc])
  end

  defp generate_path([], acc), do: acc
  defp generate_path([key|tail], acc) do
    generate_path tail, [[key.kind, (key.id || key.name)] | acc]
  end

  def from_allocate_ids_proto(%Diplomat.Proto.AllocateIdsResponse{keys: keys}) do
    keys |> Enum.map(&from_proto(&1))
  end

  def allocate_ids(type, count \\ 1) do
    keys = Enum.map 1..count, fn(_i) ->
      __MODULE__.new(type) |> __MODULE__.proto
    end

    Diplomat.Proto.AllocateIdsRequest.new(key: keys) |> Diplomat.Client.allocate_ids
    # now, just call the api...
  end

  def get(keys) when is_list(keys) do
    %LookupRequest {
      keys: Enum.map(keys, &proto(&1))
    } |> Diplomat.Client.lookup
  end
  def get(%__MODULE__{} = key) do
    get([key])
  end

  def urlsafe(%__MODULE__{} = key) do
    key
    |> proto
    |> PbKey.encode
    |> Base.url_encode64(padding: false)
  end

  def from_urlsafe(value) when is_bitstring(value) do
    value
    |> Base.url_decode64!(padding: false)
    |> PbKey.decode
    |> Key.from_proto
  end
end

defimpl Poison.Encoder, for: Diplomat.Key do
  def encode(key, options) do
    Poison.Encoder.List.encode(Diplomat.Key.path(key), options)
  end
end
