defmodule Diplomat.QueryTest do
  use ExUnit.Case
  alias Diplomat.Query
  alias Diplomat.Proto.{GqlQuery, GqlQueryArg}

  test "we can construct a query" do
    q = "select * from Assets where title = @"
    title = "20,000 Leagues Under The Sea"
    query = Query.new(q, [title])
    assert %Query{query: ^q, numbered_args: [title]} = query
  end

  test "we can convert a Query to a Proto.GqlQuery" do
    query = "select * from whatever where yes = @"
    arg = "sure"
    assert %GqlQuery{
      query_string: ^query,
      number_arg: [%GqlQueryArg{value: ^arg}],
      name_arg: []
    } = Query.new(query, [arg]) |> Query.proto
  end
end
