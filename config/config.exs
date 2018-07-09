use Mix.Config

if Mix.env() == :test do
  config :kc_auth, KCAuth, url: "http://127.0.0.1:32768"
end
