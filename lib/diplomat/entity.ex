defmodule Diplomat.Entity do
  alias Diplomat.Proto.Entity, as: PbEntity
  alias Diplomat.Proto.{CommitRequest, Mutation}
  alias Diplomat.{Key, Value, Entity}

  @type t :: %__MODULE__{
    kind: String.t,
    key:  Diplomat.Key.t,
    properties: %{String.t => Diplomat.Value.t}
  }
  defstruct kind: nil, key: nil, properties: %{}

  @spec new(%{}) :: t
  @doc """
  Creates a new `Diplomat.Entity` with the given properties.

  Instead of building a `Diplomat.Enity` struct manually, `new` is the way you
  should create your entities. `new` wraps and nests properties correctly, and
  ensures that your entities have a valid `Key` (among other things).
  """
  def new(%{}=props),
    do: %Entity{properties: value_properties(props)}

  @spec new(%{}, Diplomat.Key.t) :: t
  @doc "Creates a new `Diplomat.Entity` with the given properties and `Diplomat.Key`"
  def new(%{}=props, %Key{kind: kind}=key) do
    %Entity{
      kind: kind,
      key:  key,
      properties: value_properties(props),
    }
  end

  def new(%{}=props, kind \\ nil, id \\ nil) do
    %Entity{
      kind: kind,
      key: Key.new(kind, id),
      properties: value_properties(props)
    }
  end

  defp value_properties(%{} = props) do
    props
    |> Map.to_list
    |> Enum.map(fn {name, value} -> {to_string(name), Value.new(value)} end)
    |> Enum.into(%{})
  end

  @spec proto(t) :: Diplomat.Proto.Entity.t
  @doc """
  Generate a `Diplomat.Proto.Entity` from a given `Diplomat.Entity`. This can
  then be used to generate the binary protocol buffer representation of the
  `Diplomat.Entity`
  """
  def proto(%Entity{key: key, properties: properties}) do
    pb_properties =
      properties
      |> Map.to_list
      |> Enum.map(fn {name, value} ->
        {to_string(name), Value.proto(value)}
      end)

    %PbEntity{
      key: key |> Key.proto,
      properties: pb_properties
    }
  end

  @doc false
  def proto(%{} = properties) do
    proto(%Entity{key: nil, properties: properties})
  end

  @spec from_proto(Diplomat.Proto.Entity.t) :: t
  @doc "Create a `Diplomat.Entity` from a `Diplomat.Proto.Entity`"
  def from_proto(%PbEntity{key: pb_key, properties: pb_properties}) do
    properties =
      pb_properties
      |> Enum.map(fn {name, pb_value} ->
        {name, Value.from_proto(pb_value)}
      end)
      |> Enum.into(%{})
    key = Key.from_proto(pb_key)
    %Entity{
      kind: if key do key.kind else nil end,
      key: key,
      properties: properties
    }
  end

  @spec properties(t) :: %{}
  @doc """
  Extract a `Diplomat.Entity`'s properties as a map.

  The properties are stored on the struct as a map string keys and
  `Diplomat.Value` values. This function will allow you to extract the properties
  as a map with string keys and Elixir built-in values.

  For example, creating an `Entity` looks like the following:
  ```
  iex> entity = Entity.new(%{"hello" => "world"})
  # =>   %Diplomat.Entity{key: nil, kind: nil,
  #         properties: %{"hello" => %Diplomat.Value{value: "world"}}}
  ```

  `Diplomat.Entity.properties/1` allows you to extract those properties to get
  the following: `%{"hello" => "world"}`

  """
  def properties(%Entity{properties: properties}) do
    properties
    |> Enum.map(fn {key, value} ->
      {key, value |> recurse_properties}
    end)
    |> Enum.into(%{})
  end
  defp recurse_properties(value) do
    case value do
      %Entity{} -> value |> properties
      %Value{value: value} -> value |> recurse_properties
      value when is_list(value) -> value |> Enum.map(&recurse_properties/1)
      _ -> value
    end
  end

  def insert(%Entity{}=entity), do: insert([entity])
  def insert(entities) when is_list(entities) do
    entities
    |> Enum.map(fn(e)-> {:insert, e} end)
    |> commit_request
    |> Diplomat.Client.commit
    |> case do
      {:ok, resp} -> Key.from_commit_proto(resp)
      any -> any
    end
  end

  # at some point we should validate the entity keys
  def upsert(%Entity{}=entity), do: upsert([entity])
  def upsert(entities) when is_list(entities) do
    entities
    |> Enum.map(fn(e)-> {:upsert, e} end)
    |> commit_request
    |> Diplomat.Client.commit
    |> case do
         {:ok, resp} -> resp
         any -> any
    end
  end

  defp proto_list([], acc), do: Enum.reverse(acc)
  defp proto_list([e|tail], acc) do
    proto_list(tail, [Entity.proto(e) | acc])
  end

  @doc false
  def commit_request(opts), do: commit_request(opts, :NON_TRANSACTIONAL)
  @doc false
  def commit_request(opts, mode) do
    CommitRequest.new(
      mode: mode,
      mutations: extract_mutations(opts, [])
    )
  end
  @doc false
  def commit_request(opts, mode, trans) do
    CommitRequest.new(
      mode: mode,
      transaction_selector: {:transaction, trans.id},
      mutations: extract_mutations(opts, [])
    )
  end

  def extract_mutations([], acc), do: Enum.reverse(acc)
  def extract_mutations([{:insert, ent}|tail], acc) do
    extract_mutations(tail, [Mutation.new(operation: {:insert, proto(ent)})|acc])
  end
  def extract_mutations([{:upsert, ent}|tail], acc) do
    extract_mutations(tail, [Mutation.new(operation: {:upsert, proto(ent)})|acc])
  end
  def extract_mutations([{:update, ent}|tail], acc) do
    extract_mutations(tail, [Mutation.new(operation: {:update, proto(ent)})|acc])
  end
  def extract_mutations([{:delete, key}|tail], acc) do
    extract_mutations(tail, [Mutation.new(operation: {:delete, Key.proto(key)})|acc])
  end
end
