defmodule PgSiphonManagement.Persistence.FileExporterService do
  use GenServer

  require Logger

  alias Phoenix.PubSub

  @name :file_exporter_service
  @pubsub_topic "message_frames"

  defmodule State do
    defstruct recording: false, current_file: nil, file_path: nil
  end

  # Client API

  def start_link(_) do
    Logger.info("Starting File Exporter Service...")

    GenServer.start_link(__MODULE__, %State{}, name: @name)
  end

  def start(file_path) do
    GenServer.call(@name, {:start_export, file_path})
  end

  def stop() do
    GenServer.call(@name, :stop_export)
  end

  def recording?() do
    GenServer.call(@name, :recording?)
  end

  # Server callbacks

  def init(state) do
    {:ok, state}
  end

  def handle_call({:start_export, file_path}, _from, %{recording: false} = state) do
    Logger.info("Starting file export to #{file_path}")

    {:ok, file} = File.open(file_path, [:write])
    PubSub.subscribe(:broadcaster, @pubsub_topic)

    {:reply, {:ok, :started},
     %{state | recording: true, current_file: file, file_path: file_path}}
  end

  def handle_call({:start_export, _file_path}, _from, %{recording: true} = state) do
    {:reply, {:error, :already_started_export}, state}
  end

  def handle_call(:stop_export, _from, %{recording: true} = state) do
    Logger.info("Stopping file export")

    File.close(state.current_file)
    PubSub.unsubscribe(:broadcaster, @pubsub_topic)

    {:reply, {:ok, :stopped}, %{state | recording: false, current_file: nil}}
  end

  def handle_call(:stop_export, _from, %{recording: false} = state) do
    {:reply, {:error, :not_started}, state}
  end

  def handle_info(
        {:new_message_frame, %{type: type, payload: payload}},
        %{recording: true} = state
      ) do
    IO.binwrite(state.current_file, "#{type},#{payload}\n")

    {:noreply, state}
  end

  def handle_info({:connections_changed}, state) do
    {:noreply, state}
  end

  def handle_info({@pubsub_topic, _message}, state) do
    {:noreply, state}
  end
end
