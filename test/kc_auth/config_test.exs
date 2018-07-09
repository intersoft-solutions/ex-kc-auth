defmodule KCAuth.ConfigTest do
  @moduledoc false

  use KCAuthCase

  setup do
    {:ok, _} = start_supervised({KCAuth.Config, [otp_app: :kc_auth]})
    :ok
  end

  test "can be started and linked" do
    expected =
      :kc_auth
      |> Application.get_env(KCAuth, [])
      |> KCAuth.Keycloak.new()

    assert expected === KCAuth.Config.get(:keycloak)
  end
end
