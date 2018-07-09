defmodule KCAuth.JWTTest do
  @moduledoc false

  use KCAuthCase
  alias KCAuth.JWT

  @exp_token fixture(:exp_token)

  test "get_jws_kid/1 returns the key id of the token" do
    assert {:ok, "ZnIMkctrjpJ7FA4rOFyoljo3H6Qxi_toqRyihi3hNAE"} = JWT.get_jws_kid(@exp_token)
  end

  test "get_jws_kid/1 returns an error if no keyid is present" do
    assert {:error, :jws_no_kid} = JWT.get_jws_kid(sign())
  end

  test "peek_protected/1 returns the jws for the given token" do
    assert {:ok, jws} = JWT.peek_protected(@exp_token)

    assert jws === %JOSE.JWS{
             alg: {:jose_jws_alg_rsa_pkcs1_v1_5, :RS256},
             b64: :undefined,
             fields: %{"typ" => "JWT", "kid" => "ZnIMkctrjpJ7FA4rOFyoljo3H6Qxi_toqRyihi3hNAE"}
           }
  end

  test "peek_protected/1 returns an error if the token is invalid" do
    assert {:error, {:invalid_jwt, _}} = JWT.peek_protected(12)
    assert {:error, {:invalid_jwt, _}} = JWT.peek_protected("12")
    assert {:error, {:invalid_jwt, _}} = JWT.peek_protected(nil)
  end

  test "peek_payload/1 returns the jwt content for the given token" do
    assert {:ok, jwt} = JWT.peek_payload(@exp_token)

    assert jwt === %JOSE.JWT{
             fields: %{
               "acr" => "1",
               "allowed-origins" => [],
               "aud" => "demo-app",
               "auth_time" => 0,
               "azp" => "demo-app",
               "email_verified" => false,
               "exp" => 1_530_683_639,
               "iat" => 1_530_683_339,
               "iss" => "http://127.0.0.1:32768/auth/realms/sso-dev",
               "jti" => "e09a2fc9-3d15-4c78-bc8b-ff8fc3f682b0",
               "nbf" => 0,
               "preferred_username" => "sso-dev-1",
               "realm_access" => %{"roles" => ["offline_access", "uma_authorization"]},
               "resource_access" => %{
                 "account" => %{
                   "roles" => ["manage-account", "manage-account-links", "view-profile"]
                 }
               },
               "scope" => "email profile",
               "session_state" => "47c6e815-d536-4474-a98d-ac143efedf2d",
               "sub" => "2c4cc7b0-a1a2-43e8-b932-947065be7853",
               "typ" => "Bearer"
             }
           }
  end

  test "peek_payload/1 returns an error if the token is invalid" do
    assert {:error, {:invalid_jwt, _}} = JWT.peek_protected(12)
    assert {:error, {:invalid_jwt, _}} = JWT.peek_protected("12")
    assert {:error, {:invalid_jwt, _}} = JWT.peek_protected(nil)
  end

  defp jwk(), do: JOSE.JWK.from_oct("test")

  defp claims(claims \\ []) do
    %{"iss" => "me", "exp" => :os.system_time(:seconds) + 60}
    |> Map.merge(for {k, v} <- claims, into: %{}, do: {Atom.to_string(k), v})
  end

  defp sign(claims \\ claims()) do
    jwk()
    |> JOSE.JWT.sign(%{"alg" => "HS256"}, claims)
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  test "verify/3 returns a JWT if it is valid" do
    jwt_token = sign()
    assert {:ok, jwt} = JWT.verify(jwt_token, ["HS256"], jwk())
    assert %JWT{fields: %{"iss" => "me", "exp" => _}} = jwt
  end

  test "verify/3 returns an error if the JWT algo is not allowed" do
    jwt_token = sign()
    assert {:error, {:invalid_jwt, _}} = JWT.verify(jwt_token, ["RS256"], jwk())
  end

  test "verify/3 returns an error for invalid jwt tokens" do
    jwt_token = "2.2"
    assert {:error, {:invalid_jwt, {:badarg, ["2.2"]}}} = JWT.verify(jwt_token, ["HS256"], jwk())
  end

  test "verify/3 returns an error for expired jwt tokens" do
    jwt = claims(exp: 1_530_683_639) |> sign()
    assert {:error, :jwt_expired} = JWT.verify(jwt, ["HS256"], jwk())
  end

  test "verify/3 returns an error for jwt without an iss field" do
    jwt = sign(%{"exp" => :os.system_time()})
    assert {:error, {:invalid_jwt, :iss_missing}} = JWT.verify(jwt, ["HS256"], jwk())
  end

  test "verify/3 returns an error for jwt tokens that should not be active yet (nbf)" do
    just_ok_jwt = claims(nbf: :os.system_time(:seconds)) |> sign()
    assert {:ok, _} = JWT.verify(just_ok_jwt, ["HS256"], jwk())

    early_jwt = claims(nbf: :os.system_time(:seconds) + 61) |> sign()
    assert {:error, :jwt_not_valid_yet} = JWT.verify(early_jwt, ["HS256"], jwk())
  end
end
