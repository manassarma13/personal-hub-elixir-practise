defmodule PersonalHub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DNSCluster, query: Application.get_env(:personal_hub, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PersonalHub.PubSub},
      {Registry, keys: :unique, name: PersonalHub.Chess.Registry},
      {DynamicSupervisor, name: PersonalHub.Chess.GameSupervisor, strategy: :one_for_one}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PersonalHub.Supervisor)
  end
end
