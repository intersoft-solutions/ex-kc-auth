defmodule KCAuth.PlugTest do
  @moduledoc false

  use KCAuthCase

  @kc_auth KCAuthCase.KCAuthMock

  alias KCAuth.Plug, as: KCAPlug

  test "adds jwt and realm to the conn" do
    conn = build_conn() |> put_mock_jwt("ok")
    resp = KCAPlug.call(conn, kc_auth: @kc_auth)

    assert resp.private[:kc_auth_jwt] === %{fields: %{"typ" => "Bearer"}}
    assert resp.private[:kc_auth_realm] === %{realm: "ok"}
  end

  test "does not change the conn if jwt is invalid" do
    conn = build_conn() |> put_mock_jwt("err")
    resp = KCAPlug.call(conn, kc_auth: @kc_auth)

    assert conn === resp
  end

  test "it does not change the conn if the wrong jwt token type is given" do
    conn = build_conn() |> put_mock_jwt("wrong_typ")
    resp = KCAPlug.call(conn, kc_auth: @kc_auth)

    assert conn === resp
  end

  test "is_authenticated?/1 returns true if the conn was authenticated" do
    conn = build_conn() |> put_mock_jwt("ok") |> KCAPlug.call(kc_auth: @kc_auth)
    assert true == KCAPlug.is_authenticated?(conn)
  end

  test "is_authenticated?/1 returns false if the conn was not authenticated" do
    conn = build_conn()
    assert false == KCAPlug.is_authenticated?(conn)
  end

  test "get_claims/1 returns the JWT token if the conn was authenticated" do
    conn = build_conn() |> put_mock_jwt("ok") |> KCAPlug.call(kc_auth: @kc_auth)
    assert %{fields: %{"typ" => "Bearer"}} == KCAPlug.get_claims(conn)
  end

  test "get_claims/1 returns nil if the conn was unauthenticated" do
    conn = build_conn()
    assert nil == KCAPlug.get_claims(conn)
  end

  test "get_realm/1 returns the Realm if the conn was authenticated" do
    conn = build_conn() |> put_mock_jwt("ok") |> KCAPlug.call(kc_auth: @kc_auth)
    assert %{realm: "ok"} == KCAPlug.get_realm(conn)
  end

  test "get_realm/1 returns nil if the conn was unauthenticated" do
    conn = build_conn()
    assert nil == KCAPlug.get_realm(conn)
  end
end
