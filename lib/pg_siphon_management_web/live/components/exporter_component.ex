defmodule PgSiphonManagementWeb.ExporterComponent do
  use PgSiphonManagementWeb, :live_component

  alias PgSiphonManagement.Persistence.RecordingRequest
  alias PgSiphon.Persistence.RecordingServer

  alias Phoenix.PubSub

  def mount(socket) do
    {_, changeset} = RecordingRequest.create(%{})

    %{recording: file_recording, file_name: file_name, root_dir: root_dir} =
      :sys.get_state(:recording_server)

    {:ok,
     socket
     |> assign(form: to_form(changeset))
     |> assign(file_recording: file_recording, file_name: file_name, root_dir: root_dir)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-[400px] p-2">
      <%= if @file_recording do %>
        <.alert_bar type="success">
          <span class="font-mono text-xs">
            Recording in progress to '<%= Path.join(@root_dir, @file_name <> ".raw.csv") %>'
          </span>
        </.alert_bar>
        <div class="mt-4">
          <.button
            phx-click="stop"
            phx-target={@myself}
            phx-disable-with="Stopping ..."
            class="border border-blue-500 text-blue-500 hover:bg-blue-500 hover:text-white font-semibold py-1 px-2 rounded w-full text-xs"
          >
            Stop Recording
          </.button>
        </div>
      <% else %>
        <h3 class="text-gray-300 text-sm mb-2">Export to file</h3>
        <div class="text-gray-600 text-xs mb-4">
          <span class="font-semibold">Note:</span>
          File will be exported to dir: <span class="underline text-gray-600"><%= @root_dir %></span>
        </div>
        <.form for={@form} id="recording-form" phx-submit="submit" phx-target={@myself}>
          <.input
            field={@form[:file_name]}
            label="File name"
            placeholder="Enter file name to export file"
            autocomplete="off"
            type="text"
          />
          <.input
            type="select"
            field={@form[:file_format]}
            label="File format"
            options={[{"CSV", "csv"}, {"Text", "text"}, {"JSON", "json"}]}
          />
          <.button
            phx-disable-with="Submitting ..."
            class="border border-blue-500 text-blue-500 hover:bg-blue-500 hover:text-white font-semibold py-1 px-2 rounded w-full text-xs mt-2"
          >
            Start
          </.button>
        </.form>
      <% end %>
    </div>
    """
  end

  def handle_event(
        "submit",
        %{
          "recording_request" =>
            %{"file_format" => _file_format, "file_name" => file_name} = f_params
        },
        socket
      ) do
    case RecordingRequest.create(f_params) do
      {:ok, _new_request} ->
        {_, new_changeset} = RecordingRequest.create(%{})

        PubSub.broadcast(
          PgSiphonManagement.PubSub,
          "file_export",
          {:start_export, %{file_name: file_name}}
        )

        RecordingServer.start(file_name)

        %{recording: file_recording, file_name: file_name} =
          :sys.get_state(:recording_server)

        {:noreply,
         socket
         |> assign(:form, to_form(new_changeset))
         |> assign(file_recording: file_recording, file_name: file_name)}

      {:error, changeset} ->
        changeset =
          changeset
          |> Map.put(:action, :validate)

        {:noreply, socket |> assign(:form, to_form(changeset))}
    end
  end

  def handle_event("stop", _, socket) do
    {_status, _msg} = RecordingServer.stop()

    %{recording: file_recording, file_name: file_name} =
      :sys.get_state(:recording_server)

    # Notify pubsub to remove banner

    {:noreply,
     socket
     |> assign(file_recording: file_recording, file_name: file_name)}
  end
end
