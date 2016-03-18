defmodule Diplomat.KeyTest do
  use ExUnit.Case
  alias Diplomat.{Key}
  alias Diplomat.Proto.Key, as: PbKey

  test "creating a new key with a name" do
    assert %Key{
      kind: "Log",
      name: "testing",
      id:   nil
    } = Key.new("Log", "testing")
  end

  test "creating a new key with an id" do
    assert %Key{
      kind: "Log",
      name: nil,
      id:   123
    } = Key.new("Log", 123)
  end

  test "creating a key with an id and parent" do
    parent = Key.new("Asset")
    assert %Key{
      parent: ^parent,
      kind:   "Author",
      id:     123,
      name:   nil
    } = Key.new("Author", 123, parent)
  end

  test "creating a key with a name and parent" do
    parent = Key.new("Asset")
    assert %Key{
      parent: ^parent,
      kind:   "Author",
      id:     nil,
      name:   "20k-author"
    } = Key.new("Author", "20k-author", parent)
  end

  test "generating the path without ancestors" do
    assert [["Author", 123]] == Key.new("Author", 123) |> Key.path
    assert [["Author", "hello"]] == Key.new("Author", "hello") |> Key.path
  end

  test "generating a path with a single parent" do
    parent = Key.new("Asset", 123)
    assert [["Asset", 123], ["Author", 123]] == Key.new("Author", 123, parent) |> Key.path
  end

  test "generating a path with muliple ancestors" do
    grandparent = Key.new("Collection", "Shakespeare")
    parent      = Key.new("Play", "Romeo+Juliet", grandparent)
    child       = Key.new("Act", "ActIII", parent)

    assert [
      ["Collection", "Shakespeare"],
      ["Play", "Romeo+Juliet"],
      ["Act", "ActIII"]
    ] == Key.path(child)
  end

  test "converting to single key a protobuf" do
    pb = Key.new("Book", "Romeo+Juliet") |> Key.proto
    assert %PbKey{
      path_element: [
        %PbKey.PathElement{kind: "Book", name: "Romeo+Juliet", id: nil}
      ]
    } = pb

    assert <<_::binary>> = pb |> PbKey.encode
  end

  test "converting a key with ancestors to a protobuf" do
    pb = Key.new("Book", "Romeo+Juliet", Key.new("Collection", "Shakespeare")) |> Key.proto
    assert %PbKey{
      path_element: [
        %PbKey.PathElement{kind: "Collection", name: "Shakespeare"},
        %PbKey.PathElement{kind: "Book", name: "Romeo+Juliet"}
      ]
    } = pb

    assert <<_::binary>> = pb |> PbKey.encode
  end
end
