defmodule Datastore.EntityTest do
  use ExUnit.Case

  test "some JSON w/o null values" do
    ent = ~s<{"id":1089,"log_type":"view","access_token":"778efaf8333b2ac840f097448154bb6b","ip_address":"127.0.0.1","created_at":"2016-01-28T23:03:27.000Z","updated_at":"2016-01-28T23:03:27.000Z","log_guid":"2016-1-0b68c093a68b4bb5b16b","user_guid":"58GQA26TZ567K3C65VVN","vbid":"12345","brand":"vst","user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36"}>
            |> Poison.decode!
            |> Datastore.Entity.new

    # ensure we can encode this crazy thing
    assert <<_::binary>> = Datastore.Proto.Entity.encode(ent)
  end

  test "some JSON with null values" do
    ent = ~s<{"geo_lat":null,"geo_long":null,"id":1089,"log_type":"view","access_token":"778efaf8333b2ac840f097448154bb6b","ip_address":"127.0.0.1","created_at":"2016-01-28T23:03:27.000Z","updated_at":"2016-01-28T23:03:27.000Z","log_guid":"2016-1-0b68c093a68b4bb5b16b","user_guid":"58GQA26TZ567K3C65VVN","vbid":"12345","brand":"vst","user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36"}>
            |> Poison.decode!
            |> Datastore.Entity.new

    # ensure we can encode this crazy thing
    assert <<_::binary>> = Datastore.Proto.Entity.encode(ent)
  end
end
