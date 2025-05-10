defmodule PortfolioHermann.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PortfolioHermannWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:portfolio_hermann, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PortfolioHermann.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PortfolioHermann.Finch},
      # Start a worker by calling: PortfolioHermann.Worker.start_link(arg)
      # {PortfolioHermann.Worker, arg},
      # Start to serve requests, typically the last entry
      PortfolioHermannWeb.Endpoint,
      PortfolioHermann.Analytics
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PortfolioHermann.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PortfolioHermannWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
