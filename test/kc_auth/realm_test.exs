defmodule KCAuth.RealmTest do
  @moduledoc false

  use ExUnit.Case
  alias KCAuth.Realm

  @kc_url "http://localhost:8080"

  defp jwt_token(opts \\ []) do
    %{
      fields:
        for {k, v} <- opts, into: %{} do
          {Atom.to_string(k), v}
        end
    }
  end

  test "get_name_from_token/2 returns the realm name" do
    jwt_token = jwt_token(iss: @kc_url <> "/auth/realms/test")
    assert {:ok, "test"} == Realm.get_name_from_token(jwt_token, @kc_url)
  end

  test "get_name_from_token/2 returns the realm name ignoring case" do
    jwt_token = jwt_token(iss: @kc_url <> "/auth/ReAlMs/test")
    assert {:ok, "test"} == Realm.get_name_from_token(jwt_token, @kc_url |> String.upcase())
  end

  test "get_name_from_token/2 returns error if issuer is missing" do
    assert {:error, {:invalid_jwt, :iss_missing}} ==
             Realm.get_name_from_token(jwt_token(), @kc_url)
  end

  test "get_name_from_token/2 returns error if issuer prefix mismatches" do
    issuer = "http://127.0.0.1/auth/realms/test"
    jwt_token = jwt_token(iss: issuer)

    assert {:error, {:incorrect_issuer, ^issuer, _}} =
             Realm.get_name_from_token(jwt_token, @kc_url)
  end

  test "get_name_from_token/2 returns error if issuer has no realm uri segment" do
    issuer = @kc_url <> "/auth/realms/"
    jwt_token = jwt_token(iss: issuer)

    assert {:error, {:incorrect_issuer, ^issuer, _}} =
             Realm.get_name_from_token(jwt_token, @kc_url)
  end
end
