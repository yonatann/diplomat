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
  @iso_level :SNAPSHOT

  defstruct id: nil, state: :init, updates: [], upserts: [], inserts: [], insert_auto_ids: [], deletes: []

  def from_begin_response(%TransResponse{transaction: id}) do
    %Transaction{id: id, state: :begun}
  end


  def begin!(block) when is_function(block), do: begin!(@iso_level, block)
  def begin!(iso_level, block) when is_function(block) do
    begin!(iso_level)
    |> block.()
    |> commit!
  end

  def begin!(iso_level \\ @iso_level) do
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
    t
    |> to_commit_proto
    |> Diplomat.Client.commit
  end

  def insert(%Transaction{}=t, %Entity{}=e) do
    # the only thing I don't like about this is it prepends to the list
    # so, your last entities end up being first...
    # I guess we could reverse the list after prepending. Hrm.
    %{ t | inserts: [e | t.inserts]}
  end

  def upsert(%Transaction{}=t, %Entity{}=e) do
    %{t | upserts: [e | t.upserts]}
  end

  def update(%Transaction{}=t, %Entity{}=e) do
    %{t | updates: [e | t.updates]}
  end

  def delete(%Transaction{}=t, %Key{}=k) do
    %{t | deletes: [k | t.deletes]}
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
