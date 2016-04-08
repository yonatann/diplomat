defmodule Diplomat.Key do
  alias Diplomat.Proto.Key, as: PbKey
  alias Diplomat.Proto.PartitionId, as: PbPartition

  defstruct id: nil, name: nil, kind: nil, parent: nil, dataset_id: nil, namespace: nil

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
  defp from_path([[kind, id]|tail], parent) do
    from_path(tail, new(kind, id, parent))
  end

  def proto(%__MODULE__{}=key) do
    path_els = key
    |> path
    |> proto([])
    |> Enum.reverse

    partition = case (key.dataset_id || key.namespace) do
      nil -> nil
      _   -> Diplomat.Proto.PartitionId.new(dataset_id: key.dataset_id, namespace: key.namespace)
    end

    PbKey.new(partition_id: partition, path_element: path_els)
  end

  defp proto([], acc), do: acc
  defp proto([[kind, id]|tail], acc) when is_integer(id) do
    proto(tail, [PbKey.PathElement.new(kind: kind, id: id)|acc])
  end
  defp proto([[kind, name]|tail], acc) do
    proto(tail, [PbKey.PathElement.new(kind: kind, name: name)|acc])
  end

  def from_proto(nil), do: nil
  def from_proto(%PbKey{partition_id: nil, path_element: path_el}),
    do: from_path_proto(path_el, [])
  def from_proto(%PbKey{partition_id: %PbPartition{dataset_id: did, namespace: ns}, path_element: path_el}) do
    %{from_path_proto(path_el, []) | dataset_id: did, namespace: ns}
  end

  defp from_path_proto([], acc), do: acc |> Enum.reverse |> from_path
  defp from_path_proto([head|tail], acc) do
    from_path_proto(tail, [[head.kind, (head.id || head.name)]|acc])
  end

  def path(key) do
    key
    |> ancestors_and_self([])
    |> generate_path([])
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

  def from_allocate_ids_proto(%Diplomat.Proto.AllocateIdsResponse{key: keys}) do
    Enum.map keys, fn(k) ->
      __MODULE__.from_proto(k)
    end
  end

  def allocate_ids(type, count \\ 1) do
    keys = Enum.map 1..count, fn(_i) ->
      __MODULE__.new(type) |> __MODULE__.proto
    end

    Diplomat.Proto.AllocateIdsRequest.new(key: keys) |> Diplomat.Client.allocate_ids
    # now, just call the api...
  end
end
