defmodule PersonalHubWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PersonalHubWeb.Telemetry,
      # Start a worker by calling: PersonalHubWeb.Worker.start_link(arg)
      # {PersonalHubWeb.Worker, arg},
      # Start to serve requests, typically the last entry
      PersonalHubWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PersonalHubWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PersonalHubWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
