defmodule Diplomat.Entity do
  alias Diplomat.Proto.Entity, as: PbEntity
  alias Diplomat.{PropertyList, Key}

  # :property needs to be a list here, but I need to create a PropertyList object for that
  def proto(val), do: PbEntity.new(property: PropertyList.new(val))
  def proto(%Diplomat.Proto.Key{}=key, val) do
    PbEntity.new(key:      key,
                 property: PropertyList.new(val) )
  end
end
