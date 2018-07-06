defmodule KCAuth.Realm do
  @moduledoc """
  Keycloak realm openid configuration
  """

  @fields ~w(authorization_endpoint check_session_iframe claim_types_supported claims_parameter_supported claims_supported code_challenge_methods_supported end_session_endpoint grant_types_supported id_token_signing_alg_values_supported issuer jwks_uri registration_endpoint request_object_signing_alg_values_supported request_parameter_supported request_uri_parameter_supported response_modes_supported response_types_supported scopes_supported subject_types_supported tls_client_certificate_bound_access_tokens token_endpoint token_endpoint_auth_methods_supported token_endpoint_auth_signing_alg_values_supported token_introspection_endpoint userinfo_endpoint userinfo_signing_alg_values_supported)

  defstruct @fields |> Enum.map(&String.to_atom/1)

  @type t :: %__MODULE__{}

  @doc """
  Returns the keycloak oid config url for the specified realm
  """
  def config_uri(realm), do: "/auth/realms/#{realm}/.well-known/openid-configuration"

  @doc """
  Parses the json and creates a %RealmConfig{}
  """
  @spec from_json(binary) :: {:ok, t} | {:error, term}
  def from_json(json_string) do
    with {:ok, json} <- Jason.decode(json_string) do
      attributes =
        json
        |> Map.take(@fields)
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      {:ok, struct(__MODULE__, attributes)}
    end
  end

  @doc """
  Returns the realm name from a jwt token ensuring it matches with the specified
  keycloak url
  """
  def get_name_from_token(jwt_token, kc_url)
  def get_name_from_token(%{fields: %{"iss" => iss}}, kc_url), do: extract_realm_name(iss, kc_url)
  def get_name_from_token(_jwt, _kc_url), do: {:error, {:invalid_jwt, :iss_missing}}

  defp extract_realm_name(iss, kc_url) do
    prefix = kc_url |> URI.merge("/auth/realms/") |> URI.to_string() |> String.downcase()
    issuer = String.downcase(iss)
    realm = String.trim_leading(issuer, prefix)

    case {issuer, realm} do
      {x, x} -> {:error, {:incorrect_issuer, issuer, prefix}}
      {_, ""} -> {:error, {:incorrect_issuer, issuer, prefix}}
      {_, x} -> {:ok, x}
    end
  end
end
