defmodule PgSiphonManagement.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PgSiphonManagementWeb.Telemetry,
      PgSiphonManagement.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:pg_siphon_management, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster,
       query: Application.get_env(:pg_siphon_management, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PgSiphonManagement.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PgSiphonManagement.Finch},
      # Start a worker by calling: PgSiphonManagement.Worker.start_link(arg)
      # {PgSiphonManagement.Worker, arg},
      # Start to serve requests, typically the last entry
      PgSiphonManagementWeb.Endpoint
    ]

    {:ok, msg} =
      Application.get_env(:pg_siphon, :export)
      |> Keyword.get(:export_dir)
      |> PgSiphonManagement.Persistence.FileHelpers.make_dir_p()

    Logger.info("Export path status: #{msg}")

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PgSiphonManagement.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PgSiphonManagementWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
