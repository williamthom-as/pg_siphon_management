import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :pg_siphon_management, PgSiphonManagement.Repo,
  database: Path.expand("../pg_siphon_management_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :pg_siphon_management, PgSiphonManagementWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "qwApPbwLOfAViSZ/nZkU7tozv2491osuQkcAEjSN0pEL1QJwbm8YS1pzvNVCrMfi",
  server: false

# In test we don't send emails
config :pg_siphon_management, PgSiphonManagement.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :pg_siphon, :proxy_server,
  from_port: 1338,
  to_host: ~c"localhost",
  to_port: 5432
