defmodule MyMoney.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MyMoneyWeb.Telemetry,
      MyMoney.Repo,
      {DNSCluster, query: Application.get_env(:my_money, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MyMoney.PubSub},
      # Start a worker by calling: MyMoney.Worker.start_link(arg)
      # {MyMoney.Worker, arg},
      # Start to serve requests, typically the last entry
      MyMoneyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MyMoney.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MyMoneyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
