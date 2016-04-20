defmodule Diplomat.TransactionTest do
  use ExUnit.Case

  alias Diplomat.{Transaction, Entity, Key}
  alias Diplomat.Proto.BeginTransactionResponse, as: TransResponse
  alias Diplomat.Proto.{CommitRequest, CommitResponse, MutationResult, Mutation, RollbackResponse}

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
      mutation: Mutation.new(
        update: [Entity.new(%{phil: "burrows"}, "Person", "phil-burrows") |> Entity.proto],
        upsert: [],
        insert: [Entity.new(%{jimmy: "allen"}, "Person", 12234324) |> Entity.proto],
        insert_auto_id: [],
        delete: [Key.new("Person", "that-one-guy") |> Key.proto]
      )
    )

    assert ^commit = Transaction.to_commit_proto(t)
  end

  test "rolling back a transaction calls the server with the RollbackRequest", %{bypass: bypass, project: project} do
    Bypass.expect bypass, fn conn ->
      assert Regex.match? ~r{/datastore/v1beta2/datasets/#{project}/rollback}, conn.request_path
      Plug.Conn.resp conn, 200, <<>> # the rsponse is empty
    end

    {:ok, resp} = %Transaction{id: <<1>>} |> Transaction.rollback
    assert %RollbackResponse{} = resp
  end

  test "committing a transaction calls the server with the right data and returns a successful response (whatever that is)", %{bypass: bypass, project: project} do
    commit = CommitResponse.new(
      mutation_result: MutationResult.new(
        index_updates: 0,
        insert_auto_id_key: []
      )
    )
    Bypass.expect bypass, fn conn ->
      assert Regex.match? ~r{/datastore/v1beta2/datasets/#{project}/commit}, conn.request_path
      response = commit |> CommitResponse.encode
      Plug.Conn.resp conn, 201, response
    end

    assert {:ok, ^commit} =  %Transaction{id: <<1>>} |> Transaction.commit!
  end

  test "a transaction block begins and commits the transaction automatically", opts do
    assert_begin_and_commit!(opts)
    Transaction.begin! fn t -> t end
  end

  test "we can add inserts to a transaction" do
    e = Entity.new(%{abraham: "lincoln"}, "Body", 123)
    t = %Transaction{id: 123} |> Transaction.insert(e)
    assert Enum.count(t.inserts) == 1
    assert Enum.at(t.inserts, 0) == e
  end

  test "we can add insert_auto_ids to a transaction" do
    e = Entity.new(%{abraham: "lincoln"}, "Body")
    t = %Transaction{id: 123} |> Transaction.insert(e)
    assert Enum.count(t.insert_auto_ids) == 1
    assert Enum.at(t.insert_auto_ids, 0) == e
  end

  test "we can add upserts to a transaction" do
    e = Entity.new(%{whatever: "yes"}, "Thing", 123)
    t = %Transaction{id: 123} |> Transaction.upsert(e)
    assert Enum.count(t.upserts) == 1
    assert Enum.at(t.upserts, 0) == e
  end

  test "we can add updates to a transaction" do
    e = Entity.new(%{whatever: "yes"}, "Thing", 123)
    t = %Transaction{id: 123} |> Transaction.update(e)
    assert Enum.count(t.updates) == 1
    assert Enum.at(t.updates, 0) == e
  end

  test "we can add deletes to a transaction" do
    k = Key.new("Person", 123)
    t = %Transaction{id: 123} |> Transaction.delete(k)
    assert Enum.count(t.deletes) == 1
    assert Enum.at(t.deletes, 0) == k
  end

  def assert_begin_and_commit!(%{bypass: bypass, project: project}) do
    Bypass.expect bypass, fn conn ->
      if Regex.match? ~r{beginTransaction}, conn.request_path do
        assert Regex.match? ~r{/datastore/v1beta2/datasets/#{project}/beginTransaction}, conn.request_path
        resp = TransResponse.new(transaction: <<40, 30, 20>>) |> TransResponse.encode
        Plug.Conn.resp conn, 201, resp
      else
        assert Regex.match? ~r{/datastore/v1beta2/datasets/#{project}/commit}, conn.request_path
        resp = CommitResponse.new(
          mutation_result: MutationResult.new(
            index_updates: 0,
            insert_auto_id_key: []
          )
        ) |> CommitResponse.encode
        Plug.Conn.resp conn, 201, resp
      end
    end
  end
end
