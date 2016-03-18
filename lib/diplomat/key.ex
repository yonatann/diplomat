defmodule Diplomat.Key do
  alias Diplomat.Proto.Key, as: PbKey

  defstruct id: nil, name: nil, kind: nil, parent: nil, partition_id: nil

  def new(kind),
    do: %__MODULE__{kind: kind}
  def new(kind, id) when is_integer(id),
    do: %__MODULE__{kind: kind, id: id}
  def new(kind, name),
    do: %__MODULE__{kind: kind, name: name}

  def new(kind, id_or_name, %__MODULE__{}=parent),
    do: %{new(kind, id_or_name) | parent: parent}

  def proto(%__MODULE__{}=key) do
    path_els = key
    |> path
    |> proto([])
    |> Enum.reverse

    PbKey.new(partition_id: key.partition_id, path_element: path_els)
  end

  defp proto([], acc), do: acc
  defp proto([[kind, id]|tail], acc) when is_integer(id) do
    proto(tail, [PbKey.PathElement.new(kind: kind, id: id)|acc])
  end
  defp proto([[kind, name]|tail], acc) do
    proto(tail, [PbKey.PathElement.new(kind: kind, name: name)|acc])
  end

  def path(key) do
    key
    |> ancestors_and_self([])
    |> generate_path([])
  end

  defp ancestors_and_self(nil, acc), do: Enum.reverse(acc)
  defp ancestors_and_self(key, acc) do
    ancestors_and_self(key.parent, [key|acc])
  end

  defp generate_path([], acc), do: acc
  defp generate_path([key|tail], acc) do
    generate_path tail, [[key.kind, (key.id || key.name)] | acc]
  end
end
