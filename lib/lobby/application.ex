defmodule Lobby.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LobbyWeb.Telemetry,
      Lobby.Repo,
      {DNSCluster, query: Application.get_env(:lobby, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Lobby.PubSub},
      # Start a worker by calling: Lobby.Worker.start_link(arg)
      # {Lobby.Worker, arg},
      # Start to serve requests, typically the last entry
      LobbyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lobby.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LobbyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
