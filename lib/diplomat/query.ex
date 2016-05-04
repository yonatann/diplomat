defmodule Diplomat.Query do
  alias Diplomat.{Query, Value}
  alias Diplomat.Proto.{GqlQuery, GqlQueryArg, RunQueryRequest}

  defstruct query: nil, numbered_args: [], named_args: %{}

  def new(query), do: new(query, [])
  def new(query, args) when is_list(args) and is_binary(query) do
    %Query{
      query: query,
      numbered_args: args
    }
  end

  def new(query, args) when is_map(args) and is_binary(query) do
    %Query{
      query: query,
      named_args: args
    }
  end

  def proto(%Query{query: q, numbered_args: num, named_args: named}) do
    GqlQuery.new(
      query_string: q,
      number_arg: numbered_args(num),
      name_arg:   named_args(named)
    )
  end

  def execute(%__MODULE__{}=q) do
    RunQueryRequest.new(
      gql_query: q |> Query.proto
    ) |> Diplomat.Client.run_query
  end

  defp numbered_args(args) do
    Enum.map args, fn(i) ->
      val = i |> Value.new |> Value.proto
      GqlQueryArg.new(value: val)
    end
  end

  defp named_args(args) do
    Enum.map args, fn {k, v} ->
      val = v |> Value.new |> Value.proto
      GqlQueryArg.new(value: val, name: to_string(k))
    end
  end
end
