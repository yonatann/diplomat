defmodule Diplomat.Property do
  alias Diplomat.Proto.Property, as: PbProperty
  alias Diplomat.Value

  # def new({_name, nil}), do:
  def new({name, val}) do
    PbProperty.new(name: name, value: Value.new(val))
  end
end
