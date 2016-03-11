defmodule Datastore.PropertyListTest do
  use ExUnit.Case
  alias Datastore.PropertyList

  test "it returns and empty list for nil" do
    assert [] == PropertyList.new(%{"test" => nil})
  end
end
