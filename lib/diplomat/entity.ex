defmodule Diplomat.Entity do
  alias Diplomat.Proto.Entity, as: PbEntity
  alias Diplomat.{PropertyList, Key}

  defstruct kind: nil, key: nil, properties: []

  def new(%{}=props, kind \\ nil, id \\ nil) do
    %__MODULE__{
      kind: kind,
      key: Key.new(kind, id),
      properties: PropertyList.new(props)
    }
  end

  def add_property(%__MODULE__{}=entity, %Diplomat.Property{}=prop) do
    %{entity | properties: [prop|entity.properties]}
  end

  def proto(%__MODULE__{key: nil, properties: val}),
    do: proto(val)
  def proto(%__MODULE__{key: key, properties: val}),
    do: proto(key, val)

  def proto(val),
    do: PbEntity.new(property: PropertyList.proto(val))

  def proto(%Diplomat.Proto.Key{}=key, val) do
    PbEntity.new(key:      key,
                 property: PropertyList.proto(val) )
  end

  def from_proto(%PbEntity{property: val, key: key}) do
    %__MODULE__{
      key: Key.from_proto(key),
      properties: PropertyList.from_proto(val)
    }
  end
end
