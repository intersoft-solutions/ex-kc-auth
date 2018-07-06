defmodule KCAuthTest do
  @moduledoc false

  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @otp_app :kc_auth
  @token "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJabklNa2N0cmpwSjdGQTRyT0Z5b2xqbzNINlF4aV90b3FSeWloaTNoTkFFIn0.eyJqdGkiOiJlMDlhMmZjOS0zZDE1LTRjNzgtYmM4Yi1mZjhmYzNmNjgyYjAiLCJleHAiOjE1MzA2ODM2MzksIm5iZiI6MCwiaWF0IjoxNTMwNjgzMzM5LCJpc3MiOiJodHRwOi8vMTI3LjAuMC4xOjMyNzY4L2F1dGgvcmVhbG1zL3Nzby1kZXYiLCJhdWQiOiJkZW1vLWFwcCIsInN1YiI6IjJjNGNjN2IwLWExYTItNDNlOC1iOTMyLTk0NzA2NWJlNzg1MyIsInR5cCI6IkJlYXJlciIsImF6cCI6ImRlbW8tYXBwIiwiYXV0aF90aW1lIjowLCJzZXNzaW9uX3N0YXRlIjoiNDdjNmU4MTUtZDUzNi00NDc0LWE5OGQtYWMxNDNlZmVkZjJkIiwiYWNyIjoiMSIsImFsbG93ZWQtb3JpZ2lucyI6W10sInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJvZmZsaW5lX2FjY2VzcyIsInVtYV9hdXRob3JpemF0aW9uIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJlbWFpbCBwcm9maWxlIiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzc28tZGV2LTEifQ.oVj5AoGe7IhiWw7T46i8atwJrzOC7CXtm855DpdhtHAKjCUhqrvZ13CNgeWnZHUxd6aOq0Dbn_e9zAccTG_NHkrEnVf-Cx99oxnOQEGJQibbWisDnPPGRPTwkdL2V72RsfUN6PNJ5VW1Tw931I-7dr1yW4JdNzbq14HeMMgV1T6OB55GvF9GqD8PfHQ22GL3P9N4djBMRF9Bwb4-3_2pb03Qxc3NRSWR-BU-MzW-8cpdX0JWaAvSjF-m0HO5E2Xs-vbwHpv2RPYmozRE1J3IXAabCJXPWOGEwsQewtCo_jGM0z2KeBOwQznCCEymE9bhc-jKpMrbQcVUb9IEh4geWw"

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
