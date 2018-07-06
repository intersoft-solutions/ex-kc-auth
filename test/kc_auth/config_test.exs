defmodule KCAuth.ConfigTest do
  @moduledoc false

  use ExUnit.Case

  alias KCAuth.Config

  @otp_app :kc_auth

  setup do
    {:ok, _} = start_supervised({KCAuth.Config, [otp_app: @otp_app]})
    :ok
  end

  test "can be started and linked" do
    expected =
      :kc_auth
      |> Application.get_env(KCAuth, [])
      |> KCAuth.Keycloak.new()

    assert expected === Config.get(:keycloak)
  end
end
