defmodule Diplomat.PropertyTest do
  use ExUnit.Case
  alias Diplomat.Property

  test "returns nil for nil" do
    assert %Diplomat.Proto.Property{name: "testing", value: %Diplomat.Proto.Value{}} = Property.new({"testing", nil})
  end
end
