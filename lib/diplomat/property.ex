defmodule Diplomat.Property do
  alias Diplomat.Proto.Property, as: PbProperty
  alias Diplomat.{Value, Property, Entity}

  defstruct name: nil, value: nil

  def new({name, val}) when is_atom(name), do: new({to_string(name), val})
  def new({name, val}) do
    %__MODULE__{
      name:  name,
      value: Value.new(val)
    }
  end

  def proto(%__MODULE__{name: n, value: v}), do: proto({n, v})
  def proto({name, val}) do
    PbProperty.new(name: name, value: Value.proto(val))
  end

  def from_proto(%PbProperty{}=prop) do
    %__MODULE__{
      name:  prop.name,
      value: Value.from_proto(prop.value)
    }
  end

  def raw_value(%Property{value: %Value{value: %Entity{}=entity}}) do
    Entity.properties(entity)
  end
  def raw_value(%Property{value: %Value{}=v}), do: v.value
end
