defmodule Datastore.Entity do
  alias Datastore.Proto.Entity, as: PbEntity
  alias Datastore.{PropertyList, Key}

  # :property needs to be a list here, but I need to create a PropertyList object for that
  def new(val), do: PbEntity.new(property: PropertyList.new(val))
  def new(key, val) do
    PbEntity.new(key:      Key.new(key),
                 property: PropertyList.new(val) )
  end
end
