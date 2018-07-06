defmodule KCAuth.JWT do
  @moduledoc """
  JWT verification and keycloak specific utilities when dealing
  with tokens and realms.
  """

  defstruct fields: %{}

  def get_jws_kid(jwt_token) do
    with {:ok, %{fields: fields}} <- peek_protected(jwt_token) do
      case fields do
        %{"kid" => kid} -> {:ok, kid}
        _ -> {:error, :jws_no_kid}
      end
    end
  end

  @doc """
  Wraps JOSE.JWT.peek_protected to return :ok | :error tuples instead of raising
  """
  def peek_protected(jwt_token) do
    try do
      {:ok, JOSE.JWT.peek_protected(jwt_token)}
    rescue
      e -> {:error, {:invalid_jwt, e}}
    end
  end

  @doc """
  Wraps JOSE.JWT.peek_payload to return :ok | :error tuples instead of raising
  """
  def peek_payload(jwt_token) do
    try do
      {:ok, JOSE.JWT.peek_payload(jwt_token)}
    rescue
      e -> {:error, {:invalid_jwt, e}}
    end
  end

  @doc """
  Wraps JOSE.JWT.verify_strict and returns a %KCAuth.JWT{} with verification
  of the exp and nbf claims (allowing a 60 second clock skew)
  """
  def verify(jwt_token, allow, jwk) do
    case JOSE.JWT.verify_strict(jwk, allow, jwt_token) do
      {true, token, _} ->
        verify_claims(token)

      {false, token, _} ->
        {:error, {:invalid_jwt, token}}

      {:error, reason} ->
        {:error, {:invalid_jwt, reason}}
    end
  end

  defp verify_claims(token) do
    with :ok <- verify_exp(token.fields),
         :ok <- verify_nbf(token.fields),
         :ok <- verify_iss(token.fields) do
      {:ok, %__MODULE__{fields: token.fields}}
    end
  end

  defp verify_exp(%{"exp" => exp}) when is_number(exp) do
    case exp >= :os.system_time(:seconds) - 60 do
      true -> :ok
      false -> {:error, :jwt_expired}
    end
  end

  defp verify_exp(%{"exp" => exp}), do: {:error, {:invalid_jwt, {:exp_malformed, exp}}}

  defp verify_nbf(claims) when is_map(claims), do: claims |> Map.get("nbf") |> verify_nbf()
  defp verify_nbf(nil), do: :ok
  defp verify_nbf(nbf) when is_number(nbf), do: verify_nbf(nbf, :os.system_time(:seconds) + 60)
  defp verify_nbf(nbf), do: {:error, {:invalid_jwt, {:nbf_malformed, nbf}}}
  defp verify_nbf(nbf, now) when nbf <= now, do: :ok
  defp verify_nbf(_, _), do: {:error, :jwt_not_valid_yet}

  defp verify_iss(%{"iss" => iss}) when is_binary(iss), do: :ok
  defp verify_iss(%{"iss" => iss}), do: {:error, {:invalid_jwt, {:iss_malformed, iss}}}
  defp verify_iss(_), do: {:error, {:invalid_jwt, :iss_missing}}
end
