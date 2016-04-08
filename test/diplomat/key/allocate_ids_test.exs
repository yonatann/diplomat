defmodule Diplomat.Entity.AllocateIdsTest do
  use ExUnit.Case
  alias Diplomat.Key

  setup do
    bypass = Bypass.open
    Application.put_env(:diplomat, :endpoint, "http://localhost:#{bypass.port}")
    {:ok, bypass: bypass}
  end

  test "generating keys from an AllocateIdsResponse" do
    keys = Diplomat.Proto.AllocateIdsResponse.new(key: [
      Key.new("Log", 1) |> Key.proto,
      Key.new("Log", 2) |> Key.proto,
      Key.new("Log", 3) |> Key.proto
    ]) |> Key.from_allocate_ids_proto

    assert Enum.count(keys) == 3
    Enum.each keys, fn(k) ->
      assert k.name == nil
      assert k.kind == "Log"
      refute k.id   == nil
    end
  end

  test "allocating ids" do
    # we should get back a bunch of keys, I believe
    keys = Key.allocate_ids("Log", 20)
    assert Enum.count(keys) == 20
    # Enum.each keys fn(k) ->
    #   refute k.id == nil
    #   assert k.kind == "Log"
    #   assert k.name == nil
    # end
  end
end
