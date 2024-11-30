defmodule Med.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  import Cachex.Spec

  @hours_in_half_year 6 * 30 * 24

  @impl Application
  def start(_type, _args) do
    children = [
      MedWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:med, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Med.PubSub},
      {Cachex,
       [
         :med,
         [
           expiration: expiration(default: :timer.hours(@hours_in_half_year))
         ]
       ]},
      # Start a worker by calling: Med.Worker.start_link(arg)
      # {Med.Worker, arg},
      # Start to serve requests, typically the last entry
      MedWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Med.Supervisor]
    pid = Supervisor.start_link(children, opts)

    cache_file = Application.get_env(:med, :cache_file)

    Cachex.restore(:med, cache_file)

    pid
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    MedWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
