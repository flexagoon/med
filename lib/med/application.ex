defmodule Med.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      MedWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:med, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Med.PubSub},
      {Redix,
       {Application.get_env(:med, :redis_url),
        [
          name: :redix,
          socket_opts: [:inet6]
        ]}},
      # Start a worker by calling: Med.Worker.start_link(arg)
      # {Med.Worker, arg},
      # Start to serve requests, typically the last entry
      MedWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Med.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    MedWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
