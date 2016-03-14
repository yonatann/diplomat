defmodule Diplomat.ValueTest do
  use ExUnit.Case
  alias Diplomat.Value
  alias Diplomat.Proto.Value, as: PbVal

  test "value types" do
    [{true, :boolean}, {35, :integer}, {3.1415, :double}, {"hello", :string}]
      |> Enum.each( fn(t)->
        val = Value.proto(elem(t,0))
        pb  = %PbVal{}
        assert val == Map.put(pb, :"#{elem(t, 1)}_value", elem(t, 0) )
      end)
  end

  test "timestamp values" do
    val = Value.proto(:os.timestamp)
    assert val.timestamp_microseconds_value > 0
  end

  test "entity values" do
    val = %{"hello" => "world"} |> Value.proto
    assert %Diplomat.Proto.Entity{} = val.entity_value

    prop = val.entity_value.property |> List.first
    assert %Diplomat.Proto.Property{} = prop
    assert "hello" == prop.name
    assert %Diplomat.Proto.Value{string_value: "world"} = prop.value
  end

  test "a flat list value" do
    val = [1,2,3] |> Value.proto
    assert 3 == val.list_value |> Enum.count
  end

  test "doesn't remove nil values from a list" do
    val = [1,nil,2] |> Value.proto
    assert 3 == val.list_value |> Enum.count
  end

  test "a list with a map" do
    val = [1, %{"hello" => "world"}] |> Value.proto
    assert val.list_value |> is_list
    assert %Diplomat.Proto.Value{integer_value: 1} = val.list_value |> List.first
  end

  test "a null value" do
    assert %Diplomat.Proto.Value{} == Value.proto(nil)
  end
end
