defmodule Diplomat.PropertyListTest do
  use ExUnit.Case
  alias Diplomat.{PropertyList, Property, Value, Entity}

  @proplist [
    %Diplomat.Proto.Property{name: "hello",  value: %Diplomat.Proto.Value{string_value: "world"}},
    %Diplomat.Proto.Property{name: "math", value: %Diplomat.Proto.Value{entity_value:
                                                        %Diplomat.Proto.Entity{
                                                          property: [%Diplomat.Proto.Property{
                                                              name: "pi",
                                                              value: %Diplomat.Proto.Value{double_value: 3.1415}
                                                            }]
                                                        }
                                                      }
                             }
  ]

  @map %{
    "hello" => "world",
    "how"   => "are",
    "you"   => "doing",
    "truth" => true,
    "double"=> 3.1415
  }

  # ======= PropertyList.new ========
  test "it returns a list with a null property for nil" do
    list = PropertyList.new(%{"test" => nil})
    assert 1 == list |> Enum.count
    assert [
      %Property{
        name: "test",
        value: %Value{value: nil}
      }
    ] = list
  end


  test "creating a map from a flat list of properties" do
    list = [
      %Diplomat.Proto.Property{name: "hello", value: %Diplomat.Proto.Value{string_value: "world"}},
      %Diplomat.Proto.Property{name: "pi", value: %Diplomat.Proto.Value{double_value: 3.1415}},
    ] |> PropertyList.from_proto

    assert is_list(list)
    assert [
      %Property{name: "pi", value: %Value{value: 3.1415}},
      %Property{name: "hello", value: %Value{value: "world"}}
    ] = list
  end

  test "creating a property list from a list of nested properties" do
    list = @proplist |> PropertyList.from_proto
    assert is_list(list)
    assert [
      %Property{name: "math",
                value: %Value{value: %Entity{properties: [ %Property{name: "pi", value: %Value{value: 3.1415}} ]}}
              },
      %Property{name: "hello", value: %Value{value: "world"}}
    ] = list
  end
end
