defmodule Diplomat.PropertyListTest do
  use ExUnit.Case
  alias Diplomat.PropertyList

  test "it returns a list with a null property for nil" do
    assert 1 == PropertyList.new(%{"test" => nil}) |> Enum.count
  end
end
