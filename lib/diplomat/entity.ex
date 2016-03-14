defmodule Diplomat.Entity do
  alias Diplomat.Proto.Entity, as: PbEntity
  alias Diplomat.{PropertyList}

  defstruct key: nil, properties: nil

  def new(key, val) do
    %__MODULE__{
      key:        key,
      properties: []
    }
  end

  def proto(%__MODULE__{key: nil, properties: val}),
    do: proto(val)
  def proto(%__MODULE__{key: key, properties: val}),
    do: proto(key, val)

  def proto(val),
    do: PbEntity.new(property: PropertyList.new(val))

  def proto(%Diplomat.Proto.Key{}=key, val) do
    PbEntity.new(key:      key,
                 property: PropertyList.new(val) )
  end

  def from_proto(%PbEntity{property: val, key: key}) do
    new(key, val)
  end
end
