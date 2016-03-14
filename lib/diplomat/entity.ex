defmodule Diplomat.Entity do
  alias Diplomat.Proto.Entity, as: PbEntity
  alias Diplomat.{PropertyList}

  defstruct key: nil, value: nil

  def proto(%__MODULE__{key: nil, value: val}),
    do: proto(val)
  def proto(%__MODULE__{key: key, value: val}),
    do: proto(key, val)

  def proto(val),
    do: PbEntity.new(property: PropertyList.new(val))

  def proto(%Diplomat.Proto.Key{}=key, val) do
    PbEntity.new(key:      key,
                 property: PropertyList.new(val) )
  end
end
