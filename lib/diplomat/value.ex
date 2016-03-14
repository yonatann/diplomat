defmodule Diplomat.Value do
  alias Diplomat.Proto.Value, as: PbVal

  defstruct value: nil

  # for instance:
  #   val |> Value.proto |> PbVal.encode
  def proto(%__MODULE__{value: val}), do: proto(val)

  def proto(nil), do: PbVal.new
  def proto(val) when is_boolean(val),   do: PbVal.new(boolean_value: val)
  def proto(val) when is_integer(val),   do: PbVal.new(integer_value: val)
  def proto(val) when is_float(val),     do: PbVal.new(double_value:  val)

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

  def proto(%{}=val) do
    PbVal.new(entity_value: Diplomat.Entity.new(val))
  end

  # accepts an erlang timestamp object
  def proto({mega, sec, micro}) do
    # convert to a unix timestamp (w/microsecond precision)
    unix = mega * 1_000_000_000_000 + sec * 1_000_000 + micro
    PbVal.new(timestamp_microseconds_value: unix)
  end

  # if you already have an integer timestamp
  def proto({:time, val}), do: PbVal.new(timestamp_microseconds_value: val)

  # list values
  def proto([]),          do: proto([], [])
  def proto([head|tail]), do: proto([head|tail], [])
  defp proto([], acc) do
    PbVal.new(list_value: Enum.reverse(acc))
  end

  defp proto([head|tail], acc) do
    proto(tail, [proto(head) | acc])
  end
end
