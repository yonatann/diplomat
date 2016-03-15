defmodule Diplomat.Key do
  defstruct partition_id: nil, kind: nil, id: nil, name: nil, ancestors: []

  def path(%__MODULE__{}=key) do
    [%Diplomat.PathElement{kind: key.kind, id: key.id, name: key.name}]
  end
end
