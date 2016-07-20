defmodule Diplomat.Transaction do
  alias Diplomat.Proto.BeginTransactionResponse, as: TransResponse
  alias Diplomat.Proto.BeginTransactionRequest,  as: TransRequest
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

  defstruct id: nil, state: :init, mutations: []

  def from_begin_response(%TransResponse{transaction: id}) do
    %Transaction{id: id, state: :begun}
  end

  def begin(iso_level \\ @iso_level)
  def begin(block) when is_function(block), do: begin(@iso_level, block)

  def begin(_iso_level) do
    TransRequest.new
    |> Diplomat.Client.begin_transaction
    |> case do
         {:ok, resp} ->
           resp |> Transaction.from_begin_response
         other ->
           other
       end
  end

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
  def insert(%Transaction{}=t, [%Entity{}=e | tail]) do
    insert(%{t | mutations: [{:insert, e} | t.mutations]}, tail)
  end

  def upsert(%Transaction{}=t, %Entity{}=e), do: upsert(t, [e])
  def upsert(%Transaction{}=t, []), do: t
  def upsert(%Transaction{}=t, [%Entity{}=e | tail]) do
    upsert(%{t | mutations: [{:upsert, e} | t.mutations]}, tail)
  end

  def update(%Transaction{}=t, %Entity{}=e), do: update(t, [e])
  def update(%Transaction{}=t, []), do: t
  def update(%Transaction{}=t, [%Entity{}=e | tail]) do
    update(%{t | mutations: [{:update, e} | t.mutations]}, tail)
  end

  def delete(%Transaction{}=t, %Key{}=k), do: delete(t, [k])
  def delete(%Transaction{}=t, []), do: t
  def delete(%Transaction{}=t, [%Key{}=k | tail]) do
    delete(%{t | mutations: [{:delete, k} | t.mutations]}, tail)
  end

  def to_commit_proto(%Transaction{}=transaction) do
    CommitRequest.new(
      mode: :TRANSACTIONAL,
      transaction_selector: {:transaction, transaction.id},
      mutations: Entity.extract_mutations(transaction.mutations, [])
    )
  end
end
