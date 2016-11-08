defmodule Diplomat.Value do
  alias Diplomat.Proto.Value, as: PbVal
  alias Diplomat.Proto.Key, as: PbKey
  alias Diplomat.Proto.Entity, as: PbEntity
  alias Diplomat.Proto.ArrayValue, as: PbArray
  alias Diplomat.Proto.Timestamp, as: PbTimestamp
  alias Diplomat.Proto.LatLng, as: PbLatLng
  alias Diplomat.{Entity, Key}

  defstruct value: nil

  def new(val=%{__struct__: _}) do
    %__MODULE__{value: val}
  end
  def new(%{}=val) do
    %__MODULE__{value: Entity.new(val)}
  end

  def new(val), do: %__MODULE__{value: val}

  def from_proto(%PbVal{value_type: {:boolean_value, val}}) when is_boolean(val),
    do: new(val)
  def from_proto(%PbVal{value_type: {:integer_value, val}}) when is_integer(val),
    do: new(val)
  def from_proto(%PbVal{value_type: {:double_value, val}}) when is_float(val),
    do: new(val)
  def from_proto(%PbVal{value_type: {:string_value, val}}),
    do: new(to_string(val))
  def from_proto(%PbVal{value_type: {:blob_value, val}}) when is_bitstring(val),
    do: new(val)
  def from_proto(%PbVal{value_type: {:key_value, %PbKey{} = val}}),
    do: val |> Diplomat.Key.from_proto |> new
  def from_proto(%PbVal{value_type: {:entity_value, %PbEntity{} = val}}),
    do: val |> Diplomat.Entity.from_proto |> new
  def from_proto(%PbVal{value_type: {:array_value, %PbArray{} = val}}),
    do: val.values |> Enum.map(&Diplomat.Value.from_proto(&1)) |> new
  def from_proto(%PbVal{value_type: {:timestamp_value, %PbTimestamp{} = val}}) do
    val.seconds * 1_000_000_000 + (val.nanos || 0)
    |> DateTime.from_unix!(:nanoseconds)
    |> new
  end
  def from_proto(%PbVal{value_type: {:geo_point_value, %PbLatLng{} = val}}),
    do: new({val.latitude, val.longitude})
  def from_proto(_),
    do: new(nil)

  # convert to protocol buffer struct
  def proto(nil),
    do: PbVal.new(value_type: {:null_value, :NULL_VALUE})
  def proto(%__MODULE__{value: val}),
    do: proto(val)
  def proto(val) when is_boolean(val),
    do: PbVal.new(value_type: {:boolean_value, val})
  def proto(val) when is_integer(val),
    do: PbVal.new(value_type: {:integer_value, val})
  def proto(val) when is_float(val),
    do: PbVal.new(value_type: {:double_value, val})
  def proto(val) when is_binary(val) do
    case String.valid?(val) do
      true -> PbVal.new(value_type: {:string_value, val})
      false-> PbVal.new(value_type: {:blob_value, val})
    end
  end
  def proto(val) when is_bitstring(val),
    do: PbVal.new(value_type: {:blob_value, val})
  def proto(val) when is_list(val),
    do: proto_list(val, [])
  def proto(%DateTime{}=val) do
    timestamp = DateTime.to_unix(val, :nanoseconds)
    PbVal.new(
      value_type: {
        :timestamp_value,
        %PbTimestamp{
          seconds: div(timestamp, 1_000_000_000),
          nanos: rem(timestamp, 1_000_000_000)}
      })
  end
  def proto(%Key{} = val),
    do: PbVal.new(value_type: {:key_value, Key.proto(val)})
  def proto(%{} = val),
    do: PbVal.new(value_type: {:entity_value, Diplomat.Entity.proto(val)})
  # might need to be more explicit about this...
  def proto({latitude, longitude}) when is_float(latitude) and is_float(longitude),
    do: PbVal.new(value_type: {:geo_point_value, %PbLatLng{latitude: latitude, longitude: longitude}})

  defp proto_list([], acc) do
    PbVal.new(
      value_type: {
        :array_value,
        %PbArray{values: acc}
      })
  end
  defp proto_list([head|tail], acc) do
    proto_list(tail, acc ++ [proto(head)])
  end
end
