defmodule Datastore.PropertyTest do
  use ExUnit.Case
  alias Datastore.Property

  test "returns nil for nil" do
    assert %Datastore.Proto.Property{name: "testing", value: %Datastore.Proto.Value{}} = Property.new({"testing", nil})
  end
end
