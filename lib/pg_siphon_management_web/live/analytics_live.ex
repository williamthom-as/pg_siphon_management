defmodule PgSiphonManagementWeb.AnalyticsLive do
  use PgSiphonManagementWeb, :live_view

  alias PgSiphonManagement.Recordings

  def mount(_params, _session, socket) do
    options = %{
      filter: nil,
      offset: 0,
      max: 10
    }

    recordings = Recordings.list_recordings(options)

    socket =
      assign(
        socket,
        recordings: recordings,
        options: options
      )

    {:ok, socket}
  end

  def handle_params(%{"file" => file}, _uri, socket) do
    selected_file = Recordings.get_recording(file)

    {:noreply, assign(socket, selected_file: selected_file)}
  end

  def handle_params(%{}, _uri, socket) do
    {:noreply, assign(socket, selected_file: hd(socket.assigns.recordings))}
  end

  def render(assigns) do
    ~H"""
    <.two_columns>
      <:left_section>
        <div class="w-full rounded-sm shadow font-mono">
          <h5 class="mb-4 text-base font-mono text-sm text-gray-200">
            Recorded Logs
          </h5>
          <div class="-mb-2">
            <form phx-change="search">
              <.input
                name="search"
                value=""
                label="Search"
                placeholder="Enter file name to search"
                autocomplete="off"
                type="text"
                phx-debounce={400}
              />
            </form>
          </div>
          <ul class="my-2 space-y-2">
            <%= for recording <- @recordings do %>
              <.card recording={recording} selected_file={@selected_file}></.card>
            <% end %>
          </ul>
        </div>
      </:left_section>
      <:right_section>
        <section class="flex bg-gray-900">
          <div class="w-full mx-auto">
            <div class="relative overflow-hidden bg-gray-800 rounded-sm">
              <div class="flex-row items-center justify-between p-4 space-y-3 sm:flex sm:space-y-0 sm:space-x-4">
                <div>
                  <h4 class="mr-3 font-semibold text-gray-200">
                    Recording Analysis for '<%= @selected_file.file %>'
                  </h4>
                  <p class="text-gray-400 text-xs">
                    Created at <%= Timex.format!(
                      @selected_file.creation_time,
                      "{YYYY}-{0M}-{0D} {h24}:{m}:{s}"
                    ) %>
                  </p>
                </div>
                <div>
                  <.button phx-click="delete">Perform Analysis</.button>
                </div>
              </div>
            </div>
          </div>
        </section>
      </:right_section>
    </.two_columns>
    """
  end

  def card(assigns) do
    recording = assigns.recording
    selected_file = assigns.selected_file

    card_classes =
      if recording.file == selected_file.file do
        "text-white bg-blue-500 hover:bg-blue-500"
      else
        "bg-gray-800 hover:bg-gray-700"
      end

    text_classes =
      if recording.file == selected_file.file do
        "hover:bg-blue-500 text-blue-300"
      else
        "hover:bg-gray-700 text-gray-400"
      end

    assigns = assign(assigns, card_classes: card_classes, text_classes: text_classes)

    ~H"""
    <li>
      <div
        patch={~p"/analytics?#{[file: @recording.file]}"}
        class={"rounded-sm p-3 flex items-center space-x-2 #{@card_classes}"}
      >
        <.link
          patch={~p"/analytics?#{[file: @recording.file]}"}
          class="flex-1 whitespace-nowrap font-mono text-xs"
        >
          <div>
            <span class="font-semibold"><%= @recording.file %></span>
            <div class={"#{@text_classes} mt-2"}>
              <%= Timex.format!(@recording.creation_time, "{YYYY}-{0M}-{0D} {h24}:{m}:{s}") %>
            </div>
          </div>
        </.link>
        <div
          class={"rounded flex items-center justify-center #{@text_classes} hover:text-white cursor-pointer"}
          phx-click="delete_recording"
          phx-value-recording={@recording.file}
        >
          <Heroicons.icon name="trash" type="mini" class="h-4 w-4" />
        </div>
        <%!-- <span class="inline-flex items-center justify-center px-2 py-0.5 ms-3 text-xs font-medium rounded bg-green-500 text-white">
          Ready
        </span> --%>
      </div>
    </li>
    """
  end

  def handle_event("search", %{"search" => search_param}, socket) do
    options = %{socket.assigns.options | filter: search_param}
    recordings = Recordings.list_recordings(options)

    {:noreply, assign(socket, recordings: recordings, options: options)}
  end

  def handle_event("delete_recording", %{"recording" => recording}, socket) do
    Recordings.delete_recording(recording)

    recordings = Recordings.list_recordings(socket.assigns.options)

    {:noreply, assign(socket, recordings: recordings)}
  end
end
