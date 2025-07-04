defmodule Stacks.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      StacksWeb.Telemetry,
      Stacks.Repo,
      {DNSCluster, query: Application.get_env(:stacks, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:stacks, Oban)},
      {Phoenix.PubSub, name: Stacks.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Stacks.Finch},
      # Start a worker by calling: Stacks.Worker.start_link(arg)
      # {Stacks.Worker, arg},
      # Start to serve requests, typically the last entry
      StacksWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Stacks.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StacksWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
