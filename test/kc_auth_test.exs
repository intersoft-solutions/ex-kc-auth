defmodule KCAuthTest do
  @moduledoc false

  use KCAuthCase

  @otp_app :kc_auth
  @token fixture(:exp_token)

  test "can be started and linked" do
    pid = start_supervised!({KCAuth, otp_app: @otp_app})
    assert ^pid = GenServer.whereis(KCAuth.Supervisor)
  end

  test "can verify a JWT token" do
    use_cassette "kcauth_verify" do
      start_supervised!({KCAuth, otp_app: @otp_app})
      assert {:error, :jwt_expired} = KCAuth.verify(@token)
    end
  end

  test "caches jwt keys" do
    use_cassette "kcauth_verify_caches" do
      start_supervised!({KCAuth, otp_app: @otp_app})

      assert [] ===
               KCAuth.JWKStore
               |> Cachex.stream!()
               |> Enum.into([])

      KCAuth.verify(@token)

      assert 2 ===
               KCAuth.JWKStore
               |> Cachex.stream!()
               |> Enum.count()
    end
  end
end
