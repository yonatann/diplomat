defmodule Diplomat.EntityTest do
  use ExUnit.Case
  alias Diplomat.{Entity, Value, Key}
  alias Diplomat.Proto.Value, as: PbValue
  alias Diplomat.Proto.Entity, as: PbEntity

  test "some JSON w/o null values" do
    ent = ~s<{"id":1089,"log_type":"view","access_token":"778efaf8333b2ac840f097448154bb6b","ip_address":"127.0.0.1","created_at":"2016-01-28T23:03:27.000Z","updated_at":"2016-01-28T23:03:27.000Z","log_guid":"2016-1-0b68c093a68b4bb5b16b","user_guid":"58GQA26TZ567K3C65VVN","vbid":"12345","brand":"vst","user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36"}>
            |> Poison.decode!
            |> Diplomat.Entity.proto
    assert <<_::binary>> = Diplomat.Proto.Entity.encode(ent)
  end

  test "decode proto" do
    ent = %PbEntity{
      key: Key.new("User", 1) |> Key.proto,
      properties: [
        {"name", %PbValue{value_type: {:string_value, "elixir"}}}
      ]
    }
    ent |> PbEntity.encode |> PbEntity.decode
  end

  test "some JSON with null values" do
    ent = ~s<{"geo_lat":null,"geo_long":null,"id":1089,"log_type":"view","access_token":"778efaf8333b2ac840f097448154bb6b","ip_address":"127.0.0.1","created_at":"2016-01-28T23:03:27.000Z","updated_at":"2016-01-28T23:03:27.000Z","log_guid":"2016-1-0b68c093a68b4bb5b16b","user_guid":"58GQA26TZ567K3C65VVN","vbid":"12345","brand":"vst","user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36"}>
            |> Poison.decode!
            |> Diplomat.Entity.proto

    # ensure we can encode this crazy thing
    assert <<_::binary>> = Diplomat.Proto.Entity.encode(ent)
  end

  test "converting to proto from Entity" do
    proto = %Entity{properties: %{"hello" => "world"}} |> Entity.proto

    assert %Diplomat.Proto.Entity{
      properties: [
        {"hello", %Diplomat.Proto.Value{value_type: {:string_value, "world"}}}
      ]
    } = proto
  end

  @entity %Diplomat.Proto.Entity{
    key: %Diplomat.Proto.Key{
      path: [%Diplomat.Proto.Key.PathElement{kind: "Random", id_type: {:id, 1234567890}}]
    },
    properties: %{
      "hello" => %Diplomat.Proto.Value{value_type: {:string_value, "world"}},
      "math" => %Diplomat.Proto.Value{value_type: {:entity_value, %Diplomat.Proto.Entity{}}}
    }
  }

  test "converting from a protobuf struct" do
    assert %Entity{
      key: %Key{kind: "Random", id: 1234567890},
      properties: %{
        "math" => %Value{value: %Entity{}},
        "hello" => %Value{value: "world"}
      }
    } = Entity.from_proto(@entity)
  end

  test "generating an Entity from a flat map" do
    map = %{"access_token" => "778efaf8333b2ac840f097448154bb6b", "brand" => "vst",
            "geo_lat" => nil, "geo_long" => nil, "id" => 1089, "ip_address" => "127.0.0.1",
            "log_guid" => "2016-1-0b68c093a68b4bb5b16b", "log_type" => "view",
            "updated_at" => "2016-01-28T23:03:27.000Z",
            "user_agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36",
            "user_guid" => "58GQA26TZ567K3C65VVN", "vbid" => "12345"}
    ent = Entity.new(map, "Log")
    assert map |> Dict.keys |> length == ent.properties |> Dict.keys |> length
    assert ent.kind == "Log"
  end

  test "generating an Entity from a nested map" do
    ent = %{"person" => %{"firstName" => "Phil", "lastName" => "Burrows"}} |> Entity.new("Person")

    assert ent.kind == "Person"
    assert ent.properties |> Map.to_list |> length == 1

    first_property = ent.properties |> Map.to_list |> List.first
    {"person", person_val} = first_property

    assert %Diplomat.Value{
      value: %Diplomat.Entity{
        properties: %{
          "firstName" => %Value{value: "Phil"},
          "lastName" => %Value{value: "Burrows"}
        }
      }
    } = person_val
  end

  test "encoding an entity that has a nested entity" do
    ent = %{"person" => %{"firstName" => "Phil"}} |> Entity.new("Person")
    # IO.puts "proto: #{inspect Entity.proto(ent)}"
    assert <<_ :: binary>> = ent |> Entity.proto |> Diplomat.Proto.Entity.encode
  end

  test "pulling properties properties" do
    ent = %{"person" => %{"firstName" => "Phil"}} |> Entity.new("Person")
    assert %{"person" => %{"firstName" => "Phil"}} == ent |> Entity.properties
  end

  test "pulling properties of arrays of properties" do
    properties = %{"person" => %{"firstName" => "Phil", "dogs" => [%{"name" => "Fido"}, %{"name" => "Woofer"}]}}
    # cast to proto
    ent = properties |> Entity.new("Person") |> Entity.proto |> Entity.from_proto
    assert  properties == ent |> Entity.properties
  end


  test "property names are converted to strings" do
    entity = Entity.new(%{:hello => "world"}, "CodeSnippet")
    assert %{"hello" => "world"} == Entity.properties(entity)
  end

  test "building an entity with a custom key" do
    entity = Entity.new(%{"hi" => "there"}, %Key{kind: "Message", namespace: "custom"})
    assert %Entity{
      properties: %{},
      key: %Key{
        kind: "Message",
        namespace: "custom"
      }
    } = entity
  end
end
