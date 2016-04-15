defmodule Diplomat.PropertyTest do
  use ExUnit.Case
  alias Diplomat.{Property, Value}

  # ======= Property.proto ========
  test "returns nil for nil" do
    assert %Diplomat.Proto.Property{name: "testing", value: %Diplomat.Proto.Value{}} = Property.proto({"testing", nil})
  end

  test "converting from a Property to a proto struct" do
    proto = %Property{name: "hello", value: 3.1415} |> Property.proto

    assert ^proto = %Diplomat.Proto.Property{
                      name:  "hello",
                      value: %Diplomat.Proto.Value{double_value: 3.1415}
                    }
  end

  # ====== Property.new ===========
  test "can create a %Propert{} from a key, value pair" do
    assert %Property{
      name: "hello",
      value: %Value{value: "world"}
    } = {"hello", "world"} |> Property.new
  end

  test "it converts keys to strings" do
    property = Property.new({:random, 123})
    assert "random" == property.name
  end

  # ====== Property.from_proto ======
  test "can convert a Proto.Property into a Property" do
    proto = Diplomat.Proto.Property.new(name: "hello", value: Diplomat.Proto.Value.new(string_value: "world"))
    assert %Property{
        name:  "hello",
        value: %Value{value: "world"}
      } = proto |> Property.from_proto
  end

  # ===== Serialization =======
  test "can serialize a %Property{} as a protocol buffer" do
    assert <<_::binary>> = Property.new({"hello", "world"}) |> Property.proto |> Diplomat.Proto.Property.encode
  end
end
