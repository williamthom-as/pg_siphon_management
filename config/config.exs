# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

require Logger

alias PgSiphonManagement.FileHelpers

config :pg_siphon_management,
  ecto_repos: [PgSiphonManagement.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :pg_siphon_management, PgSiphonManagementWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PgSiphonManagementWeb.ErrorHTML, json: PgSiphonManagementWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PgSiphonManagement.PubSub,
  live_view: [signing_salt: "UvQCsraA"]

config :pg_siphon_management, :export,
  export_dir: System.user_home() |> Path.join(".pg_siphon_management")

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :pg_siphon_management, PgSiphonManagement.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  pg_siphon_management: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  pg_siphon_management: [
    args: ~w(
      --config=tailwind.config.js
      --input=../priv/static/assets/app.css.tailwind
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :dart_sass,
  version: "1.77.8",
  pg_siphon_management: [
    args: ~w(
      css/app.scss ../priv/static/assets/app.css.tailwind
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Proxy server configuration
config :pg_siphon, :proxy_server,
  from_port: 1337,
  to_host: ~c"localhost",
  to_port: 5432

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

if File.exists?("/etc/pg_siphon/config.exs") do
  IO.puts("Loading external config ...")

  import_config "/etc/pg_siphon/config.exs"
end
