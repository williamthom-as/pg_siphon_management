# PgSiphonManagement

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Docker

Build 
```bash
docker build -t pg_siphon .
```

Run
```bash
docker run -p 4004:4004 -p 5432:5432 -p 1337:1337 -e SECRET_KEY_BASE=$(mix phx.gen.secret) -e PORT=4004 pg_siphon
```

Make sure if psql is running locally to use `--add-host=host.docker.internal:host-gateway`.

You may also want to host the recordings/analysis directory outside of the container. To do this, you can mount a volume to the container. For example, to mount the current directory to the container, you can add `-v <my_local_dir>:/etc/pg_siphon_management` to the `docker run` command.

and configure prod.exs as:

```elixir
config :pg_siphon, :proxy_server,
  to_host: ~c"host.docker.internal",
  to_port: 5432, # change if needed
  from_port: 1337 # change if needed
```

If having issues with connecting to psql - read [here](https://stackoverflow.com/questions/24319662/from-inside-of-a-docker-container-how-do-i-connect-to-the-localhost-of-the-mach).