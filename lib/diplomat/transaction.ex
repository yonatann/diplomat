defmodule Diplomat.Transaction do
  alias Diplomat.Proto.BeginTransactionResponse, as: TransResponse
  alias Diplomat.Proto.BeginTransactionRequest,  as: TransRequest
  alias Diplomat.Proto.Mutation
  alias Diplomat.Proto.RollbackRequest
  alias Diplomat.Proto.CommitRequest
  alias Diplomat.{Transaction, Entity, Key}


  @doc """
  ```
  Transaction.begin
  |> Transaction.save(entity)
  |> Transaction.save(entity2)
  |> Transaction.commit
  ```

  OR

  ```
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

  def begin(block) when is_function(block), do: begin(@iso_level, block)
  def begin(iso_level, block) when is_function(block) do
    # the try block defines a new scope that isn't accessible in the rescue block
    # so we need to begin the transaction here so both have access to the var
    transaction = begin(iso_level)
    try do
      transaction
      |> block.()
      |> commit
    rescue
      e ->
        rollback(transaction)
        {:error, e}
    end
  end

  def begin(iso_level \\ @iso_level) do
    TransRequest.new(isolation_level: iso_level)
    |> Diplomat.Client.begin_transaction
    |> case do
         {:ok, resp} ->
           resp |> Transaction.from_begin_response
         other ->
           other
       end
  end

  def commit(%Transaction{}=t) do
    t
    |> to_commit_proto
    |> Diplomat.Client.commit
  end

  # require the transaction to have an ID
  def rollback(%Transaction{id: id}) when not is_nil(id) do
    RollbackRequest.new(transaction: id)
    |> Diplomat.Client.rollback
  end

  def insert(%Transaction{}=t, %Entity{}=e), do: insert(t, [e])
  def insert(%Transaction{}=t, []), do: t
  def insert(%Transaction{}=t, [%Entity{key: key}=e | tail]) do
    case Key.complete?(key) do
      true ->
        insert(%{t | inserts: [e | t.inserts]}, tail)
      false ->
        insert(%{t | insert_auto_ids: [e | t.insert_auto_ids]}, tail)
    end
  end

  def upsert(%Transaction{}=t, %Entity{}=e), do: upsert(t, [e])
  def upsert(%Transaction{}=t, []), do: t
  def upsert(%Transaction{}=t, [%Entity{}=e | tail]) do
    upsert(%{t | upserts: [e | t.upserts]}, tail)
  end

  def update(%Transaction{}=t, %Entity{}=e), do: update(t, [e])
  def update(%Transaction{}=t, []), do: t
  def update(%Transaction{}=t, [%Entity{}=e | tail]) do
    update(%{t | updates: [e | t.updates]}, tail)
  end

  def delete(%Transaction{}=t, %Key{}=k), do: delete(t, [k])
  def delete(%Transaction{}=t, []), do: t
  def delete(%Transaction{}=t, [%Key{}=k | tail]) do
    delete(%{t | deletes: [k | t.deletes]}, tail)
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
