defmodule Datastore.PropertyTest do
  use ExUnit.Case
  alias Datastore.Property

  test "returns nil for nil" do
    assert nil == Property.new({"testing", nil})
  end
end
