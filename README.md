# PgSiphonManagement

## Overview

PgSiphon sits between your application and Postgres, acting as a proxy to observe, collect, and analyse streams of database activity.

It can be used to:
- monitor and visualise database activity in real-time.
- compare performance and impact on database activity before/after refactoring.
- verify that what you *think* should be happening, is *actually* happening [especially useful for ORMs].

PgSiphon should not be used in production environments, but rather as a development tool for debugging/finding performance improvements.

PgSiphon has:
- a very small overhead on application performance,
- requires only application configuration change,
- observes **all** traffic, but only records on demand.
- allows different message formats to be included/ignored for analysis.

## Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/741fcb7a-d537-4781-8572-4f19e1e92147" alt="PgSiphon UI" width="600">
  <br>
  <em>PgSiphon architecture diagram showing data flow between application, proxy and database</em>
</p>

## Usage

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

## To Do
- Audit rules to match against query behaviour.
- Binary format for file export/analysis.