defmodule Datastore.PropertyListTest do
  use ExUnit.Case
  alias Datastore.PropertyList

  test "it returns a list with a null property for nil" do
    assert 1 == PropertyList.new(%{"test" => nil}) |> Enum.count
  end
end
