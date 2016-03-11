defmodule Datastore.Value do
  alias Datastore.Proto.Value, as: PbVal

  def new(nil), do: PbVal.new
  def new(val) when is_boolean(val),   do: PbVal.new(boolean_value: val)
  def new(val) when is_integer(val),   do: PbVal.new(integer_value: val)
  def new(val) when is_float(val),     do: PbVal.new(double_value:  val)

  def new(%{}=val) do
    PbVal.new(entity_value: Datastore.Entity.new(val))
  end

  # is_binary isn't very good since there's a separate blob...
  def new(val) when is_binary(val) do
    case String.valid?(val) do
      true -> PbVal.new(string_value: val)
      false-> PbVal.new(blob_value: val)
    end
  end

  def new(val) when is_bitstring(val) do
    PbVal.new(blob_value:    val)
  end

  def new(%{}=val) do
    PbVal.new(entity_value: Datastore.Entity.new(val))
  end

  # accepts an erlang timestamp object
  def new({mega, sec, micro}) do
    # convert to a unix timestamp (w/microsecond precision)
    unix = mega * 1_000_000_000_000 + sec * 1_000_000 + micro
    PbVal.new(timestamp_microseconds_value: unix)
  end

  # if you already have an integer timestamp
  def new({:time, val}), do: PbVal.new(timestamp_microseconds_value: val)

  # list values
  def new([]),          do: new([], [])
  def new([head|tail]), do: new([head|tail], [])
  defp new([], acc) do
    PbVal.new(list_value: Enum.reverse(acc))
  end

  defp new([head|tail], acc) do
    new(tail, [new(head) | acc])
  end
end
