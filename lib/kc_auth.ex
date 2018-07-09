defmodule KCAuth do
  @moduledoc """
  Documentation for KCAuth.
  """

  alias KCAuth.{JWT, Realm, Keycloak, JWKStore, Config}

  @doc false
  def child_spec(opts), do: KCAuth.Supervisor.child_spec(opts)

  @doc """
  Verifies the passed jwt token.
  If the token is good the token and realm will be returned
  """
  @spec verify(binary) :: {:ok, JWT.t(), Realm.t()} | {:error, term}
  def verify(jwt_token) do
    keycloak = Config.get(:keycloak)

    with {:ok, kid} <- JWT.get_jws_kid(jwt_token) do
      case verify_cached(jwt_token, kid, keycloak) do
        {:error, :jwk_not_found} ->
          verify_uncached(jwt_token, kid, keycloak)

        any ->
          any
      end
    end
  end

  defp verify_cached(jwt_token, kid, keycloak) do
    with {:ok, {key, realm}} <- JWKStore.get_jwk(kid),
         {:ok, jwt} <- JWT.verify(jwt_token, keycloak.allowed_algos, key) do
      {:ok, jwt, realm}
    end
  end

  defp verify_uncached(jwt_token, kid, keycloak) do
    with {:ok, payload} <- JWT.peek_payload(jwt_token),
         {:ok, realm} <- Realm.get_name_from_token(payload, keycloak.url),
         {:ok, config} <- Keycloak.get_realm_config(keycloak, realm),
         {:ok, jwks} <- Keycloak.get_jwks(keycloak, config),
         {:ok, true} <- JWKStore.add_jwks(jwks, config) do
      verify_cached(jwt_token, kid, keycloak)
    end
  end
end
