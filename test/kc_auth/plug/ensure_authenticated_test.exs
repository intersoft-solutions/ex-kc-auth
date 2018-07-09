defmodule KCAuth.Plug.EnsureAuthenticatedTest do
  @moduledoc false

  use KCAuthCase
  alias KCAuth.Plug, as: KCAPlug
  alias KCAuth.Plug.EnsureAuthenticated

  @kc_auth KCAuthCase.KCAuthMock

  test "it stops an unauthenticated connection" do
    conn =
      build_conn()
      |> EnsureAuthenticated.call([])

    assert conn.status == 401
    assert conn.resp_body == ~S({"reason":"unauthenticated"})
    assert conn.halted == true
  end

  test "it passes through an authenticated connection" do
    conn =
      build_conn()
      |> put_mock_jwt("ok")
      |> KCAPlug.call(kc_auth: @kc_auth)

    authenticated = EnsureAuthenticated.call(conn, [])

    assert authenticated === conn
    assert authenticated.status == nil
    assert authenticated.resp_body == nil
    assert authenticated.halted == false
  end
end
