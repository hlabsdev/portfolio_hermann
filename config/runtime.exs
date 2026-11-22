import Config

# Configuration qui s'applique quand PHX_SERVER=true est défini
if System.get_env("PHX_SERVER") do
  config :portfolio_hermann, PortfolioHermannWeb.Endpoint, server: true
end

# Autorise la surcharge du port d'écoute par la variable d'environnement PORT
# dans tous les environnements (utile pour les tests locaux et le déploiement).
if port = System.get_env("PORT") do
  config :portfolio_hermann, PortfolioHermannWeb.Endpoint, http: [port: String.to_integer(port)]
end

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "8080")

  config :portfolio_hermann, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :portfolio_hermann, PortfolioHermannWeb.Endpoint,
    # Force le démarrage du serveur en production
    server: true,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Écoute sur toutes les interfaces IPv4
      ip: {0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # Configuration SSL optionnelle (à décommenter si nécessaire)
  # config :portfolio_hermann, PortfolioHermannWeb.Endpoint,
  #   https: [
  #     port: 443,
  #     cipher_suite: :strong,
  #     keyfile: System.get_env("SSL_KEY_PATH"),
  #     certfile: System.get_env("SSL_CERT_PATH")
  #   ],
  #   force_ssl: [hsts: true]
end
