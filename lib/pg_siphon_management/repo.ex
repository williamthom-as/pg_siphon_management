defmodule PgSiphonManagement.Repo do
  use Ecto.Repo,
    otp_app: :pg_siphon_management,
    adapter: Ecto.Adapters.SQLite3
end
