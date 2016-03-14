defmodule Diplomat.PropertyTest do
  use ExUnit.Case
  alias Diplomat.Property

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
end
