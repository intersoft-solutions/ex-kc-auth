defmodule KCAuth.SupervisorTest do
  @moduledoc false

  use KCAuthCase

  test "start_link/2 starts a supervisor with a configured jwk store" do
    {:ok, _pid} = KCAuth.Supervisor.start_link(url: "test", allowed_algos: [])

    assert [
             {KCAuth.JWKStore, _, :supervisor, [Cachex]},
             {KCAuth.Config, _, :worker, [KCAuth.Config]}
           ] = Supervisor.which_children(KCAuth.Supervisor)
  end
end
