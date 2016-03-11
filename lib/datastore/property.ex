defmodule Datastore.Property do
  alias Datastore.Proto.Property, as: PbProperty
  alias Datastore.Value

  # def new({_name, nil}), do:
  def new({name, val}) do
    PbProperty.new(name: name, value: Value.new(val))
  end
end
