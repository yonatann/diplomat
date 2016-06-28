defmodule Diplomat do
  defmodule Proto do
    use Protobuf, from: Path.expand("datastore_v1beta3.proto", __DIR__)
  end
end
