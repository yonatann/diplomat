defmodule Diplomat.Entity.InsertTest do
  use ExUnit.Case
  alias Diplomat.Proto.CommitResponse
  alias Diplomat.Proto.MutationResult
  alias Diplomat.Proto.Key, as: PbKey

  alias Diplomat.{Key, Entity}

  setup do
    bypass = Bypass.open
    Application.put_env(:diplomat, :endpoint, "http://localhost:#{bypass.port}")
    {:ok, bypass: bypass}
  end

  test "extracting keys from CommitResponse" do
    response = CommitResponse.new(
      mutation_result: MutationResult.new(
        index_updates: 2,
        insert_auto_id_key: [
          Key.new("Thing", 1) |> Key.proto,
          Key.new("Thing", 2) |> Key.proto
        ]
      )
    )

    keys = response |> Key.from_commit_proto
    assert Enum.count(keys) == 2
    Enum.each keys, fn(k)->
      assert %Key{} = k
    end
  end

  test "saving a single entity", %{bypass: bypass} do
    {:ok, project} = Goth.Config.get(:project_id)
    {kind, name}   = {"TestBook", "my-book-unique-id"}

    entity = Entity.new(
      %{"name" => "My awesome book", "author" => "Phil Burrows"},
      kind, name
    )

    Bypass.expect bypass, fn conn ->
      assert Regex.match?(~r{/datastore/v1beta2/datasets/#{project}/commit}, conn.request_path)
      resp = CommitResponse.new(
        mutation_result: MutationResult.new(
          index_updates: 1,
          insert_auto_id_key: [ (Key.new(kind, name) |> Key.proto) ]
        )
      ) |> CommitResponse.encode
      Plug.Conn.resp conn, 201, resp
    end

    keys = Entity.save(entity)
    assert Enum.count(keys) == 1
    retkey = hd(keys)

    assert retkey.kind == kind
    assert retkey.name == name
  end
end
