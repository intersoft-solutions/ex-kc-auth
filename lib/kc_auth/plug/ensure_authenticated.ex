defmodule KCAuth.Plug.EnsureAuthenticated do
  @moduledoc """
  This Plug ensures that the connection is correctly authenticated
  against the keycloak server.

  In order for this plug to work correcly the KCAuth.Plug has to be placed
  in front of this one so that authentication info is added to the connection.

  For now the response is hardcoded to a JSON response, ideally it should be
  configurable using a error handler behavior.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    maybe_stop(conn, not KCAuth.Plug.is_authenticated?(conn))
  end

  defp maybe_stop(conn, false), do: conn

  defp maybe_stop(conn, true) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{reason: :unauthenticated}))
    |> halt()
  end
end
