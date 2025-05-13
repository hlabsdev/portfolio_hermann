import Config

config :portfolio_hermann, PortfolioHermannWeb.Endpoint,
  server: true,
  url: [host: System.get_env("PHX_HOST") || "localhost", port: 8080],
  http: [
    ip: {0, 0, 0, 0},
    port: String.to_integer(System.get_env("PORT") || "4000")
  ],
  check_origin: false,
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

config :logger, level: :info
