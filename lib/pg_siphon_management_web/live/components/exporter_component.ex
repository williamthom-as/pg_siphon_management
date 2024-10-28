defmodule PgSiphonManagementWeb.ExporterComponent do
  use PgSiphonManagementWeb, :live_component

  alias PgSiphonManagement.Persistence.FileExportRequest

  def mount(socket) do
    {_, changeset} = FileExportRequest.create(%{})

    %{recording: file_recording, file_path: file_path} =
      :sys.get_state(:file_exporter_service)

    {:ok,
     socket
     |> assign(form: to_form(changeset))
     |> assign(file_recording: file_recording, file_path: file_path)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-64">
      <%= if @file_recording do %>
        <.alert_bar type="success">
          <span class="font-mono text-xs">Recording in progress to '<%= @file_path %>'</span>
        </.alert_bar>
      <% else %>
        <.form for={@form} id="file-export-form" phx-submit="submit" phx-target={@myself}>
          <.input
            field={@form[:file_path]}
            label="File Path"
            placeholder="Enter full path to export file"
            autocomplete="off"
            type="text"
          />
          <.input
            type="select"
            field={@form[:file_format]}
            label="File Format"
            options={[{"Text", "text"}, {"CSV", "csv"}, {"JSON", "json"}]}
          />
          <.button
            phx-disable-with="Submitting ..."
            class="border border-blue-500 text-blue-500 hover:bg-blue-500 hover:text-white font-semibold py-1 px-2 rounded w-full text-xs"
          >
            Start
          </.button>
        </.form>
      <% end %>
    </div>
    """
  end

  def handle_event("submit", %{"file_export_request" => f_params}, socket) do
    case FileExportRequest.create(f_params) do
      {:ok, _new_request} ->
        {_, new_changeset} = FileExportRequest.create(%{})

        socket = put_flash(socket, :info, "Triggered successfully!")

        # trigger FileExporterService impl todo.
        # use new_request.file_path

        IO.puts("Here!!")

        %{recording: file_recording, file_path: file_path} =
          :sys.get_state(:file_exporter_service)

        {:noreply,
         socket
         |> assign(:form, to_form(new_changeset))
         |> assign(file_recording: file_recording, file_path: file_path)}

      {:error, changeset} ->
        changeset =
          changeset
          |> Map.put(:action, :validate)

        {:noreply, socket |> assign(:form, to_form(changeset))}
    end
  end
end
