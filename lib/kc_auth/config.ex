defmodule KCAuth.Config do
  @moduledoc """
  Storage of the keycloak config in ets
  """
  use GenServer

  def start_link(opts) do
    kc =
      opts
      |> Keyword.fetch!(:otp_app)
      |> Application.get_env(KCAuth, [])
      |> KCAuth.Keycloak.new()

    GenServer.start_link(__MODULE__, [kc], name: __MODULE__)
  end

  def get(key) do
    [{^key, [val]}] = :ets.lookup(__MODULE__, key)
    val
  end

  def init(keycloak) do
    tab = :ets.new(__MODULE__, [:set, :protected, :named_table])
    true = :ets.insert(__MODULE__, {:keycloak, keycloak})
    {:ok, tab}
  end
end
