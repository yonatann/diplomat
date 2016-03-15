defmodule Diplomat.KeyTest do
  use ExUnit.Case
  alias Diplomat.{Key}

  test "generating a key path with just a kind" do
    key = %Key{kind: "Asset"} |> Key.path
    assert key == [%Diplomat.PathElement{kind: "Asset"}]
  end

  test "generating a key path with a kind and id" do
    key = %Key{kind: "Asset", id: 124234} |> Key.path
    assert key == [%Diplomat.PathElement{kind: "Asset", id: 124234}]
  end
end
