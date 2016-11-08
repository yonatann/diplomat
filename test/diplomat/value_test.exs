defmodule Diplomat.ValueTest do
  use ExUnit.Case
  alias Diplomat.Value
  alias Diplomat.Proto.Value, as: PbVal
  alias Diplomat.Proto.Key, as: PbKey

  # ==== Value.from_proto ======
  test "creating from protobuf struct" do
    [true, 35, 3.1415, "hello", nil]
      |> Enum.each( fn(i)->
        proto = Value.proto(i)
        val   = %Value{value: i}
        assert val == Value.from_proto(proto)
      end)
  end

  test "create key from protobuf key" do
    proto = %PbVal{
      value_type: {
        :key_value, %PbKey{
          path: [
            PbKey.PathElement.new(kind: "User", id_type: {:id, 1})
          ]
        }
      }
    }
    key = Value.from_proto(proto).value
    assert key.kind == "User"
    assert key.id == 1
  end

  test "creating from a protobuf struct with a list value" do
    proto = [1,2,3] |> Value.proto

    assert %Value{value: [
        %Value{value: 1}, %Value{value: 2}, %Value{value: 3}
      ]} = Value.from_proto(proto)
  end

  # ===== Value.proto -> convert to Proto.Value =====
  test "value types" do
    [{true, :boolean}, {35, :integer}, {3.1415, :double}, {"hello", :string}]
      |> Enum.each( fn(t)->
        value = elem(t, 0)
        type = elem(t, 1)
        val = value |> Value.new |> Value.proto
        pb  = %PbVal{}
        assert val == Map.put(pb, :value_type, {:"#{type}_value", value})
      end)
  end

  test "timestamp values" do
    now = DateTime.utc_now
    val = Value.proto(now)
    timestamp = elem(val.value_type, 1)
    assert timestamp.seconds == DateTime.to_unix(now, :seconds)
    {ms, _} = now.microsecond
    assert timestamp.nanos == ms * 1_000
  end

  test "geo coordinate values" do
    val = Value.proto({-37.5, 75.6})
    assert %PbVal{
      value_type: {:geo_point_value, %Diplomat.Proto.LatLng{latitude: -37.5, longitude: 75.6}}
    } == val
  end

  test "a flat list value" do
    val = [1,2,3] |> Value.proto
    {:array_value, array} = val.value_type
    assert 3 == array.values |> Enum.count
    proto_values =
      array.values
      |> Enum.map(fn item ->
        {:integer_value, value} = item.value_type
        value
      end)
    assert proto_values == [1, 2, 3]
  end

  test "an empty list value" do
    val = [] |> Value.proto
    {:array_value, array} = val.value_type
    assert array.values == []
  end

  test "doesn't remove nil values from a list" do
    val = [1,nil,2] |> Value.proto
    {:array_value, array} = val.value_type
    assert 3 == array.values |> Enum.count
  end

  test "a list with a map" do
    val = [1, %{"hello" => "world"}] |> Value.proto
    {:array_value, pb_array} = val.value_type
    assert 2 == pb_array.values |> Enum.count
    assert %Diplomat.Proto.Value{
      value_type: {:integer_value, 1},
    } = pb_array.values |> List.first
  end

  test "a null value" do
    assert %PbVal{
      value_type: {:null_value, :NULL_VALUE}
    } = Value.proto(nil)
  end

  test "converting from a Value struct to the proto version" do
    assert %Diplomat.Proto.Value{
      value_type: {:string_value, "hello"}
    } = %Value{value: "hello"} |> Value.proto
  end
end
