defmodule Diplomat.Query do
  alias Diplomat.{Query, Value}
  alias Diplomat.Proto.{GqlQuery, GqlQueryParameter, RunQueryRequest}

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
      allow_literals: allow_literals(num, named),
      positional_bindings: positional_bindings(num),
      named_bindings:   named_bindings(named)
    )
  end

  def execute(%__MODULE__{}=q) do
    RunQueryRequest.new(
      query_type: {:gql_query, q |> Query.proto}
    ) |> Diplomat.Client.run_query
  end

  defp positional_bindings(args) do
    args
    |> Enum.map(fn(i) ->
      val = i |> Value.new |> Value.proto
      GqlQueryParameter.new(parameter_type: {:value, val})
    end)
  end

  defp named_bindings(args) do
    args
    |> Enum.map(fn {k, v} ->
      val = v |> Value.new |> Value.proto
      {to_string(k), GqlQueryParameter.new(parameter_type: {:value, val})}
    end)
  end

  defp allow_literals([], {}), do: false
  defp allow_literals(_, _), do: true
end
