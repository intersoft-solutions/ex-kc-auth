defmodule KCAuth.JWKStore do
  @moduledoc """
  JWK Cache for fast kid => {key, realm} lookups
  """

  import Cachex.Spec, only: [limit: 1, expiration: 1]

  @doc false
  def child_spec(opts) do
    size = Keyword.get(opts, :jwk_cache_size, 500)

    lim_policy =
      limit(
        # the limit provided
        size: size,
        # the policy to use for eviction
        policy: Cachex.Policy.LRW,
        # how much to reclaim on bound expiration
        reclaim: 0.1,
        # options to pass to the policy
        options: []
      )

    exp_policy =
      expiration(
        default: :timer.hours(24),
        interval: :timer.minutes(15)
      )

    %{
      id: __MODULE__,
      start: {Cachex, :start_link, [__MODULE__, [limit: lim_policy, expiration: exp_policy]]},
      type: :supervisor
    }
  end

  def get_jwk(key_id) do
    case Cachex.get(__MODULE__, key_id) do
      {:ok, nil} -> {:error, :jwk_not_found}
      any -> any
    end
  end

  def add_jwks(keys, realm) when is_list(keys) do
    pairs =
      for %{"kid" => kid} = key <- keys do
        {kid, {key, realm}}
      end

    Cachex.put_many(__MODULE__, pairs)
  end
end

#   @doc false
#   def realm_cache_spec(opts) do
#     name = Keyword.get(opts, :realm_cache, KCAuth.RealmCache)
#     size = Keyword.get(opts, :realm_cache_size, 500)

#     lim_policy =
#       limit(
#         # the limit provided
#         size: size,
#         # the policy to use for eviction
#         policy: Cachex.Policy.LRW,
#         # how much to reclaim on bound expiration
#         reclaim: 0.1,
#         # options to pass to the policy
#         options: []
#       )

#     exp_policy =
#       expiration(
#         default: 4 * @hour,
#         interval: 15 * @minute
#       )

#     %{
#       id: name,
#       start: {Cachex, :start_link, [name, [limit: lim_policy, expiration: exp_policy]]},
#       type: :supervisor
#     }
#   end
