defmodule Datastore.Entity do
  alias Datastore.Proto.Entity, as: PbEntity
  alias Datastore.{PropertyList, Key}

  # :property needs to be a list here, but I need to create a PropertyList object for that
  def new(val), do: PbEntity.new(property: PropertyList.new(val))
  def new(%Datastore.Proto.Key{}=key, val) do
    PbEntity.new(key:      key,
                 property: PropertyList.new(val) )
  end
end
