defmodule KCAuth.Keycloak do
  @moduledoc """
  Keycloak interactions.

  This module implements the interactions needed to verify authentication with
  keycloak.
  """
  defstruct url: nil, allowed_algos: nil

  alias KCAuth.Realm

  @default_algo "RS256"
  @type t :: %__MODULE__{
          url: binary,
          allowed_algos: [binary]
        }

  @doc """
  Create a new keycloak client
  """
  @spec new([{:url, binary}, {:allowed_algos, [binary]}]) :: t
  def new(opts) do
    %__MODULE__{
      url: Keyword.fetch!(opts, :url),
      allowed_algos: Keyword.get(opts, :allowed_algos, [@default_algo])
    }
  end

  @doc """
  Fetches the realm openid endpoint configuration from the keycloak server.
  """
  @spec get_realm_config(t, binary) :: {:ok, Realm.t()} | {:error, term}
  def get_realm_config(kc, realm) do
    url = kc.url |> URI.merge(Realm.config_uri(realm)) |> URI.to_string()

    with {:ok, resp} <- HTTPoison.get(url),
         :ok <- ensure_200_status(resp) do
      Realm.from_json(resp.body)
    end
  end

  @doc """
  Fetches the realm JWKS from the keycloak server.
  """
  @spec get_jwks(t, Realm.t()) :: {:ok, term} | {:error, term}
  def get_jwks(kc, realm_config) do
    with {:ok, resp} <- HTTPoison.get(realm_config.jwks_uri),
         :ok <- ensure_200_status(resp),
         {:ok, jwks} <- Jason.decode(resp.body) do
      extract_jwks(jwks, kc.allowed_algos)
    end
  end

  defp ensure_200_status(%{status_code: c}) when c >= 200 and c <= 300, do: :ok
  defp ensure_200_status(resp), do: {:error, resp}

  defp extract_jwks(%{"keys" => keys}, allowed_algos) when is_list(keys) do
    extracted = Enum.filter(keys, &(&1["alg"] in allowed_algos))
    if extracted == [], do: {:error, :no_useable_jwks}, else: {:ok, extracted}
  end

  defp extract_jwks(invalid, _), do: {:error, {:invalid_jwks, invalid}}
end
