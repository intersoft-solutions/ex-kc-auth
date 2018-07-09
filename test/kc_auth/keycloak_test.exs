defmodule KCAuth.KeycloakTest do
  @moduledoc false

  use KCAuthCase
  alias KCAuth.Keycloak
  doctest Keycloak

  @kc_url "http://127.0.0.1:32768"
  @realm "sso-dev"

  test "new/1 returns a new keycloak struct" do
    assert Keycloak.new(url: @kc_url) === %Keycloak{url: @kc_url, allowed_algos: ["RS256"]}
  end

  test "get_realm_config/2" do
    use_cassette "get_realm_config" do
      {:ok, config} =
        [url: @kc_url]
        |> Keycloak.new()
        |> Keycloak.get_realm_config(@realm)

      assert config.issuer == "#{@kc_url}/auth/realms/#{@realm}"
    end
  end

  test "get_jwks/2 returns the json web key set for the realm" do
    use_cassette "get_jwks" do
      kc = Keycloak.new(url: @kc_url)
      {:ok, config} = Keycloak.get_realm_config(kc, @realm)
      {:ok, jwks} = Keycloak.get_jwks(kc, config)

      assert is_list(jwks)
      assert length(jwks) === 2

      for key <- jwks do
        assert key["alg"] == "RS256"
        assert key["kty"] == "RSA"
        assert key["e"] == "AQAB"
        assert key["use"] == "sig"
        assert is_binary(key["kid"]) && String.length(key["kid"]) > 40
        assert is_binary(key["n"]) && String.length(key["kid"]) > 40
      end
    end
  end

  test "get_jwks/2 only allows jwks that are in allowed_algos" do
    use_cassette "get_jwks" do
      kc = Keycloak.new(url: @kc_url, allowed_algos: ["HS512"])
      {:ok, config} = Keycloak.get_realm_config(kc, @realm)
      assert {:error, :no_useable_jwks} === Keycloak.get_jwks(kc, config)
    end
  end
end
