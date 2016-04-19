defmodule Diplomat.Transaction do
  alias Diplomat.Proto.BeginTransactionResponse, as: TransResponse
  alias Diplomat.Proto.BeginTransactionRequest,  as: TransRequest
  alias Diplomat.Proto.Mutation
  alias Diplomat.Proto.CommitRequest
  alias Diplomat.{Transaction, Entity, Key}


  @doc """
  ```
  Transaction.begin
  |> Transaction.save(entity)
  |> Transaction.save(entity2)
  |> Transaction.commit

  OR

  Transaction.begin fn t ->
    # auto-begin
    t
    |> Transaction.save(entity)
    |> Transaction.save(entity2)
    # auto-commits on exit
  end

  ```
  """

  defstruct id: nil, state: :init, updates: [], upserts: [], inserts: [], insert_auto_ids: [], deletes: []

  def from_begin_response(%TransResponse{transaction: id}) do
    %Transaction{id: id, state: :begun}
  end

  def begin!(iso_level \\ :SNAPSHOT) do
    TransRequest.new(isolation_level: iso_level)
    |> Diplomat.Client.begin_transaction
    |> case do
      {:ok, resp} ->
        resp |> Transaction.from_begin_response
      other ->
        other
    end
  end

  def commit!(%Transaction{}=t) do
    IO.puts "the transaction: #{inspect t}"
    t
    |> to_commit_proto
    |> Diplomat.Client.commit
  end

  def to_commit_proto(%Transaction{}=transaction) do
    CommitRequest.new(
      mode: :TRANSACTIONAL,
      transaction: transaction.id,
      mutation: Mutation.new(
        update: Enum.map(transaction.updates, &Entity.proto/1),
        upsert: Enum.map(transaction.upserts, &Entity.proto/1),
        insert: Enum.map(transaction.inserts, &Entity.proto/1),
        insert_auto_id: Enum.map(transaction.insert_auto_ids, &Entity.proto/1),
        delete: Enum.map(transaction.deletes, &Key.proto/1),
      )
    )
  end
end
