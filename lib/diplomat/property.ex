defmodule Diplomat.Property do
  alias Diplomat.Proto.Property, as: PbProperty
  alias Diplomat.Value

  defstruct name: nil, value: nil

  def proto(%__MODULE__{name: n, value: v}), do: proto({n, v})
  def proto({name, val}) do
    PbProperty.new(name: name, value: Value.proto(val))
  end
end
