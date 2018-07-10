defmodule KCAuthTest do
  @moduledoc false

  use KCAuthCase

  @token fixture(:exp_token)

  defmodule MyAuth do
    use KCAuth, otp_app: :kc_auth
  end

  test "can be started and linked" do
    pid = start_supervised!(MyAuth)
    assert ^pid = GenServer.whereis(KCAuth.Supervisor)
  end

  test "can override init and modify the config at runtime" do
    defmodule MyAuthInit do
      use KCAuth, otp_app: :kc_auth

      def init(_cfg) do
        [url: "test", allowed_algos: ["test"]]
      end
    end

    _pid = start_supervised!(MyAuthInit)

    assert %KCAuth.Keycloak{
             allowed_algos: ["test"],
             url: "test"
           } === KCAuth.Config.get(:keycloak)
  end

  test "can verify a JWT token" do
    use_cassette "kcauth_verify" do
      start_supervised!(MyAuth)
      assert {:error, :jwt_expired} = MyAuth.verify(@token)
    end
  end

  test "caches jwt keys" do
    use_cassette "kcauth_verify_caches" do
      start_supervised!(MyAuth)

      assert [] ===
               KCAuth.JWKStore
               |> Cachex.stream!()
               |> Enum.into([])

      MyAuth.verify(@token)

      assert 2 ===
               KCAuth.JWKStore
               |> Cachex.stream!()
               |> Enum.count()
    end
  end

  test "delegates to plug functions" do
    assert false == build_conn() |> MyAuth.is_authenticated?()
    assert nil == build_conn() |> MyAuth.current_token()
    assert nil == build_conn() |> MyAuth.current_realm()
    assert nil == build_conn() |> MyAuth.current_claims()
  end
end
