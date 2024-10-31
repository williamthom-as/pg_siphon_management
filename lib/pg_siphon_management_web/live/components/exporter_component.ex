defmodule PgSiphonManagementWeb.ExporterComponent do
  use PgSiphonManagementWeb, :live_component

  alias PgSiphonManagement.Persistence.FileExportRequest
  alias PgSiphonManagement.Persistence.FileExporterService

  def mount(socket) do
    {_, changeset} = FileExportRequest.create(%{})

    %{recording: file_recording, file_name: file_name, root_dir: root_dir} =
      :sys.get_state(:file_exporter_service)

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
            Recording in progress to '<%= Path.join(@root_dir, @file_name) %>'
          </span>
        </.alert_bar>
        <div class="mt-4">
          <.button
            phx-click="stop"
            phx-target={@myself}
            phx-disable-with="Stopping ..."
            class="border border-red-500 text-red-500 hover:bg-red-500 hover:text-white font-semibold py-1 px-2 rounded w-full text-xs"
          >
            Stop Recording
          </.button>
        </div>
      <% else %>
        <h3 class="text-gray-300 text-sm mb-2">Export to file</h3>
        <div class="text-gray-600 text-xs mb-4">
          <span class="font-semibold">Note:</span>
          File will be exported to dir: <span class="underline text-gray-500"><%= @root_dir %></span>
        </div>
        <.form for={@form} id="file-export-form" phx-submit="submit" phx-target={@myself}>
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
          "file_export_request" =>
            %{"file_format" => _file_format, "file_name" => file_name} = f_params
        },
        socket
      ) do
    case FileExportRequest.create(f_params) do
      {:ok, _new_request} ->
        {_, new_changeset} = FileExportRequest.create(%{})

        socket = put_flash(socket, :info, "Triggered successfully!")

        # trigger FileExporterService impl todo.

        # IO.puts(file_path)
        FileExporterService.start(file_name)

        %{recording: file_recording, file_name: file_name} =
          :sys.get_state(:file_exporter_service)

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
    {status, msg} = FileExporterService.stop()

    %{recording: file_recording, file_name: file_name} =
      :sys.get_state(:file_exporter_service)

    socket = put_flash(socket, :info, "#{status} #{msg}")

    {:noreply,
     socket
     |> assign(file_recording: file_recording, file_name: file_name)}
  end
end
