defmodule KCAuth.Plug do
  @moduledoc """
  Plug for keycloak multi tenant authentication

  Looks for a token in the `Authorization` header and attempts to verify it.
  If verification is successfull the realm and the token will be stored in the
  conn.

  Since keycloak hands out multiple token types we want to ensure only the access
  token is allowed. This token contains %{"typ" => "Bearer"} inside the claims.

  If verification is not successful nothing will be added in the conn. It is therefor
  vital if authentication is required to setup a plug that checks if the realm/token
  were stored.
  """

  import Plug.Conn

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, opts) do
    kcauth = Keyword.get(opts, :kc_auth, KCAuth)

    conn
    |> get_req_header("authorization")
    |> extract_token_from_headers
    |> verify_token(kcauth)
    |> ensure_bearer_typ()
    |> update_conn(conn)
  end

  @doc """
  Determines if the conn was authenticated using KCAuth
  """
  @spec is_authenticated?(Plug.Conn.t()) :: boolean
  def is_authenticated?(conn) do
    Map.has_key?(conn.private, :kc_auth_jwt) && Map.has_key?(conn.private, :kc_auth_realm)
  end

  @doc """
  Returns the JWT token or nil if this connection was not authenticated
  """
  @spec current_token(Plug.Conn.t()) :: nil | KCAuth.JWT.t()
  def current_token(conn), do: conn.private[:kc_auth_jwt]

  @doc """
  Returns the JWT fields or nil if this connection was not authenticated
  """
  @spec current_claims(Plug.Conn.t()) :: nil | %{binary => term}
  def current_claims(conn), do: conn.private |> Map.get(:kc_auth_jwt, %{}) |> Map.get(:fields)

  @doc """
  Returns the Realm or nil if this connection was not authenticated
  """
  @spec current_realm(Plug.Conn.t()) :: nil | KCAuth.Realm.t()
  def current_realm(conn), do: conn.private[:kc_auth_realm]

  defp extract_token_from_headers([]), do: nil
  defp extract_token_from_headers(["Bearer: " <> token | _]), do: token
  defp extract_token_from_headers([_ | t]), do: extract_token_from_headers(t)

  defp verify_token(nil, _), do: nil
  defp verify_token(token, kcauth), do: kcauth.verify(token)

  defp ensure_bearer_typ({:ok, %{fields: %{"typ" => "Bearer"}} = jwt, realm}), do: {jwt, realm}
  defp ensure_bearer_typ(_), do: nil

  defp update_conn(nil, conn), do: conn

  defp update_conn({jwt, realm}, conn) do
    conn
    |> put_private(:kc_auth_jwt, jwt)
    |> put_private(:kc_auth_realm, realm)
  end
end
