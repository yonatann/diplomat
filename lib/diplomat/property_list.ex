defmodule Diplomat.PropertyList do
  alias Diplomat.Proto.Property, as: PbProperty
  alias Diplomat.{Property, Entity}

  def new(%{}=prop), do: prop |> Map.to_list |> from_list([])
  def new(prop) when is_list(prop), do: from_list(prop, [])
  def new(prop), do: from_list([prop], [])

  defp from_list([], acc) do
    acc |> Enum.reverse
  end

  defp from_list([head|tail], acc) do
    from_list(tail, [Property.new(head)|acc])
  end

  def proto(%{}=prop),
    do: prop |> Map.to_list |> proto_from_list([])
  def proto(prop) when is_list(prop),
    do: proto_from_list(prop, [])
  def proto(prop),
    do: proto_from_list([prop], [])

  defp proto_from_list([], acc) do
    acc |> Enum.reverse
  end

  defp proto_from_list([head|tail], acc) do
    proto_from_list(tail, [Property.proto(head)|acc])
  end

  def from_proto(%PbProperty{}=prop),
    do: from_proto([prop], [])
  def from_proto([head|tail]),
    do: from_proto([head|tail], [])

  defp from_proto([], acc),
    do: acc
  defp from_proto([head|tail], acc) do
    from_proto(tail, [Property.from_proto(head)|acc])
  end
end
