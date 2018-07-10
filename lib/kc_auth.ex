defmodule KCAuth do
  @moduledoc """
  Defines a keycloak authentication module.

  When used, the module expects the `:otp_app` as option.
  The `:otp_app` should point to an OTP application that has
  the KCAuth configuration. For example, the repository:

      defmodule MyAuth do
        use KCAuth, otp_app: :my_app
      end

  Could be configured with:

      config :my_app, KCAuth,
        url: "http://127.0.0.1:8080",
        allowed_algos: ["RS256"]

  In case the KCAuth needs to be dynamically configured, for example by
  reading a system environment variable, such can be done via the
  `c:init/2` callback. It will receive the config which can then be modified.

      def init(config) do
        Keyword.put(config, :url, System.get_env("KC_URL"))
      end

  """

  alias KCAuth.{JWT, Realm, Keycloak, JWKStore, Config}

  @callback init(term) :: term

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @otp_app Keyword.fetch!(opts, :otp_app)
      @behaviour KCAuth

      @doc false
      def child_spec(opts \\ []) do
        @otp_app
        |> Application.get_env(KCAuth, [])
        |> init()
        |> KCAuth.Supervisor.child_spec()
      end

      @doc false
      def init(x), do: x

      defdelegate verify(jwt_token), to: KCAuth
      defdelegate is_authenticated?(conn), to: KCAuth.Plug
      defdelegate current_token(conn), to: KCAuth.Plug
      defdelegate current_claims(conn), to: KCAuth.Plug
      defdelegate current_realm(conn), to: KCAuth.Plug

      defoverridable KCAuth
    end
  end

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
