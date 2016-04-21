defmodule Diplomat.Query do
  alias Diplomat.Query
  alias Diplomat.Proto.{GqlQuery, GqlQueryArg}

  defstruct query: nil, numbered_args: [], named_args: %{}

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
    IO.puts "the numbered: #{inspect num}"
    GqlQuery.new(
      query_string: q,
      number_arg: Enum.map(num, fn i -> GqlQueryArg.new(value: i) end),
      name_arg:    Enum.map(named, fn {key, val} -> GqlQueryArg.new(value: val, name: key) end)
    )
  end
end
