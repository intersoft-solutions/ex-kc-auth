defmodule KCAuth.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    children = [
      {KCAuth.Config, opts},
      {KCAuth.JWKStore, opts}
    ]

    sup_opts = [strategy: :one_for_one]
    Supervisor.init(children, sup_opts)
  end
end
