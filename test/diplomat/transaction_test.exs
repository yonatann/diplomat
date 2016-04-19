defmodule Diplomat.TransactionTest do
  use ExUnit.Case

  alias Diplomat.{Transaction, Entity, Key}
  alias Diplomat.Proto.BeginTransactionResponse, as: TransResponse
  alias Diplomat.Proto.{CommitRequest, CommitResponse, MutationResult}

  setup do
    bypass = Bypass.open
    Application.put_env(:diplomat, :endpoint, "http://localhost:#{bypass.port}")
    {:ok, project} = Goth.Config.get(:project_id)
  {:ok, bypass: bypass, project: project}
  end

  test "creating a transaction from a transaction response returns a transaction" do
    assert %Transaction{id: <<1,2,4>>, state: :begun} = Transaction.from_begin_response(TransResponse.new(transaction: <<1, 2, 4>>))
  end

  test "beginning a transaction calls the server with a BeginTransactionRequest and returns a Transaction struct", %{bypass: bypass, project: project} do
    Bypass.expect bypass, fn conn ->
      assert Regex.match? ~r{/datastore/v1beta2/datasets/#{project}/beginTransaction}, conn.request_path
      resp = TransResponse.new(transaction: <<40, 30, 20>>) |> TransResponse.encode
      Plug.Conn.resp conn, 201, resp
    end

    trans = Transaction.begin!
    assert %Transaction{state: :begun, id: <<40, 30, 20>>} = trans
  end

  test "converting a transaction to a CommitRequest" do
    t = %Transaction{id: <<1,2,3>>, state: :begun,
                     updates: [Entity.new(%{phil: "burrows"}, "Person", "phil-burrows")],
                     inserts: [Entity.new(%{jimmy: "allen"},  "Person", 12234324)],
                     deletes:  [Key.new("Person", "that-one-guy")]
      }

    commit = CommitRequest.new(
      mode: :TRANSACTIONAL,
      transaction: <<1,2,3>>,
      mutation: [
        update: [Entity.new(%{phil: "burrows"}, "Person", "phil-burrows") |> Entity.proto],
        upsert: [],
        insert: [Entity.new(%{jimmy: "allen"}, "Person", 12234324) |> Entity.proto],
        insert_auto_id: [],
        delete: [Key.new("Person", "that-one-guy") |> Key.proto]
      ]
    )

    assert commit = Transaction.to_commit_proto(t)
  end

  test "committing a transaction calls the server with the right data and returns a successful response (whatever that is)", %{bypass: bypass, project: project} do
    Bypass.expect bypass, fn conn ->
      assert Regex.match? ~r{/datastore/v1beta2/datasets/#{project}/commit}, conn.request_path
      resp = CommitResponse.new(
        mutation_result: MutationResult.new(
          index_updates: 0,
          insert_auto_id_key: []
        )
      ) |> CommitResponse.encode
      Plug.Conn.resp conn, 201, resp
    end

    {:ok, response} = %Transaction{id: <<1>>} |> Transaction.commit!
    assert response = CommitResponse.new
  end
end
