defmodule Diplomat.Transaction do
  alias Diplomat.Proto.BeginTransactionResponse, as: TransResponse
  alias Diplomat.Proto.BeginTransactionRequest,  as: TransRequest
  alias Diplomat.Proto.CommitRequest
  alias Diplomat.Transaction

  defstruct [:id]

  def from_begin_response(%TransResponse{transaction: id}) do
    %Transaction{id: id}
  end

  def begin!(iso_level \\ :SNAPSHOT) do
    {:ok, resp} = TransRequest.new(isolation_level: iso_level)
                  |> Diplomat.Client.begin_transaction

    resp |> Transaction.from_begin_response
  end

  # def commit!(%Transaction{id: id}, %Mutation{}=mutattion) do
  # end
end
