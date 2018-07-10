defmodule KCAuth.ConfigTest do
  @moduledoc false

  use KCAuthCase

  test "can be started and linked" do
    {:ok, _} = start_supervised({KCAuth.Config, [url: "test"]})
  end

  test "allows retrieving the keycloak config" do
    {:ok, _} = start_supervised({KCAuth.Config, [url: "test"]})

    assert KCAuth.Config.get(:keycloak) === %KCAuth.Keycloak{
             url: "test",
             allowed_algos: ["RS256"]
           }
  end
end
