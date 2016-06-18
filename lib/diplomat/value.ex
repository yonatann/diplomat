defmodule Diplomat.Value do
  alias Diplomat.Proto.Value, as: PbVal
  alias Diplomat.{Entity, Property, Key}

  defstruct value: nil

  # if it's a struct (presumably, something we know about), just pass it along
  def new(val=%{__struct__: _}) do
    %__MODULE__{ value: val }
  end
  def new(%{}=val) do
    %__MODULE__{ value: Entity.new(val) }
  end

  def new(val), do: %__MODULE__{value: val}

  def from_proto(%PbVal{boolean_value: val}) when is_boolean(val),
    do: new(val)
  def from_proto(%PbVal{integer_value: val}) when is_integer(val),
    do: new(val)
  def from_proto(%PbVal{double_value: val}) when is_float(val),
    do: new(val)
  def from_proto(%PbVal{string_value: val}) when is_binary(val),
    do: new(val)
  def from_proto(%PbVal{blob_value: val}) when is_bitstring(val),
    do: new(val)
  def from_proto(%PbVal{timestamp_microseconds_value: val}) when is_integer(val),
    do: new(val) # need to convert this to a timestamp of some sort
  def from_proto(%PbVal{key_value: val}) when not is_nil(val) do
    val |> Diplomat.Key.from_proto |> new
  end
  def from_proto(%PbVal{entity_value: val}) when not is_nil(val) do
    val |> Diplomat.Entity.from_proto |> new
  end

  def from_proto(%PbVal{list_value: val}) when is_list(val) and length(val) > 0 do
    val
    |> Enum.map(&Diplomat.Value.from_proto(&1))
    |> new
  end

  # must be a nil value if it makes it this far
  def from_proto(_), do: new(nil)

  # convert to protocol buffer struct
  def proto(%__MODULE__{value: val}), do: proto(val)

  def proto(nil), do: PbVal.new
  def proto(val) when is_boolean(val),   do: PbVal.new(boolean_value: val)
  def proto(val) when is_integer(val),   do: PbVal.new(integer_value: val)
  def proto(val) when is_float(val),     do: PbVal.new(double_value:  val)

  def proto(%Key{} = val) do
    PbVal.new(key_value: Key.proto(val))
  end

  def proto(%{}=val) do
    PbVal.new(entity_value: Diplomat.Entity.proto(val))
  end


  # is_binary isn't very good since there's a separate blob...
  def proto(val) when is_binary(val) do
    case String.valid?(val) do
      true -> PbVal.new(string_value: val)
      false-> PbVal.new(blob_value: val)
    end
  end

  def proto(val) when is_bitstring(val) do
    PbVal.new(blob_value:    val)
  end

  # accepts an erlang timestamp object
  def proto({mega, sec, micro}) do
    # convert to a unix timestamp (w/microsecond precision)
    unix = mega * 1_000_000_000_000 + sec * 1_000_000 + micro
    PbVal.new(timestamp_microseconds_value: unix)
  end

  def proto({{y, m, d}, {h, mn, s}}=timestamp) do
    unix = timestamp |> Timex.DateTime.from_erl |> Timex.to_unix
    # need this to have microseconds, so multiply by 1_000_000
    PbVal.new(timestamp_microseconds_value: unix * 1_000_000)
  end

  # if you already have an integer timestamp
  def proto({:time, val}), do: PbVal.new(timestamp_microseconds_value: val)

  # list values (empty lists aren't an option)
  def proto([head|tail]), do: proto([head|tail], [])
  defp proto([], acc) do
    PbVal.new(list_value: Enum.reverse(acc))
  end
  defp proto([head|tail], acc) do
    proto(tail, [proto(head) | acc])
  end
end
