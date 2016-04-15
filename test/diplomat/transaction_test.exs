defmodule Diplomat.TransactionTest do
  use ExUnit.Case

  alias Diplomat.Transaction
  alias Diplomat.Proto.BeginTransactionResponse, as: TransResponse

  setup do
    bypass = Bypass.open
    Application.put_env(:diplomat, :endpoint, "http://localhost:#{bypass.port}")
  {:ok, bypass: bypass}
  end

  test "creating a transaction from a transaction response returns a transaction" do
    assert %Transaction{id: <<1,2,4>>} = Transaction.from_begin_response(TransResponse.new(transaction: <<1, 2, 4>>))
  end

  test "beginning a transaction calls the server with a BeginTransactionRequest and returns a Transaction struct", %{bypass: bypass} do
    {:ok, project} = Goth.Config.get(:project_id)
    Bypass.expect bypass, fn conn ->
      assert Regex.match? ~r{/datastore/v1beta2/datasets/#{project}/beginTransaction}, conn.request_path
      resp = TransResponse.new(transaction: <<40, 30, 20>>) |> TransResponse.encode
      Plug.Conn.resp conn, 201, resp
    end

    trans = Transaction.begin!
    assert %Transaction{} = trans
  end
end
