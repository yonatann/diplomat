defmodule Diplomat.PropertyListTest do
  use ExUnit.Case
  alias Diplomat.{PropertyList, Property, Value, Entity}

  test "it returns a list with a null property for nil" do
    assert 1 == PropertyList.new(%{"test" => nil}) |> Enum.count
  end

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
