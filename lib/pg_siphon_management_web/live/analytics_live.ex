defmodule PgSiphonManagementWeb.AnalyticsLive do
  use PgSiphonManagementWeb, :live_view

  alias PgSiphonManagement.Recordings
  alias Phoenix.PubSub

  # TODO: empty states, progress states.

  def mount(_params, _session, socket) do
    PubSub.subscribe(PgSiphonManagement.PubSub, "analysis")
    PubSub.subscribe(PgSiphonManagement.PubSub, "recording")

    options = %{
      filter: nil,
      offset: 0,
      max: 10
    }
    recordings = Recordings.list_recordings(options)

    %{recording: recording} =
      :sys.get_state(:file_exporter_service)

    socket =
      assign(
        socket,
        recordings: recordings,
        options: options,
        page_title: "Analytics",
        in_progress: [],
        recording: recording
      )

    {:ok, socket}
  end

  def handle_params(%{"file_name" => file_name}, _uri, socket) do
    selected_file = Recordings.get_recording(file_name)

    {_, analysis} = Recordings.get_analysis(file_name)

    {:noreply,
     assign(
       socket,
       selected_file: selected_file,
       analysis: analysis
     )}
  end

  def handle_params(%{}, _uri, socket) do
    selected_file = List.first(socket.assigns.recordings)

    {_, analysis} = if selected_file do
      Recordings.get_analysis(selected_file.file_name)
    else
      nil
    end


    {:noreply,
     assign(
       socket,
       selected_file: selected_file,
       analysis: analysis
     )}
  end

  def render(assigns) do
    ~H"""
    <%= if @recording do %>
      <div class="p-3">
        <.alert_bar type="danger">
          <div class="flex flex-row justify-start items-center space-x-4">
            <Heroicons.icon name="arrow-path" type="outline" class="h-6 w-6 animate-spin" />
            <span class="font-mono text-xs">
              Recording in progress...
            </span>
          </div>
        </.alert_bar>
      </div>
    <% end %>
    <%= unless Enum.empty?(@in_progress) do %>
      <div class="p-3">
        <.alert_bar type="success">
          <div class="flex flex-row justify-start items-center space-x-4">
            <Heroicons.icon name="arrow-path" type="outline" class="h-6 w-6 animate-spin" />
            <span class="font-mono text-xs">
                There are files currently being processed: <%= Enum.join(@in_progress, ", ") %>
            </span>
          </div>
        </.alert_bar>
      </div>
    <% end %>
    <.two_columns>
      <:left_section>
        <div class="w-full rounded-sm shadow font-mono">
          <h5 class="mb-4 text-base font-mono text-sm text-gray-200">
            Recorded Logs
          </h5>
          <.search_form></.search_form>
          <.cards recordings={@recordings} selected_file={@selected_file}></.cards>
        </div>
      </:left_section>
      <:right_section>
        <%= if @selected_file do %>
          <.internal_header>
            <:title>
              Recording Analysis for '<%= @selected_file.file_name %>'
            </:title>
            <:sub_title>
              Created at <%= Timex.format!(
                @selected_file.creation_time,
                "{YYYY}-{0M}-{0D} {h24}:{m}:{s}"
              ) %>
            </:sub_title>
            <:left_section>
              <div class="font-mono text-xs text-gray-500 italic">
                <%= unless @selected_file.has_analysis do %>
                  No analysis has been performed yet.
                <% end %>
              </div>
              <div>
                <.button phx-click="perform_analysis">Perform Analysis</.button>
              </div>
            </:left_section>
          </.internal_header>
          <div class="text-gray-600 mt-4">
            <%= if @analysis do %>
              <.dashboard_container>
                <.dashboard_card title="Total Count of Messages">
                  <div class="text-md text-gray-200">
                    <%= @analysis.content["total_count"] %>
                  </div>
                </.dashboard_card>
                <.dashboard_card title="Duration">
                  <div class="text-md text-gray-200">-</div>
                </.dashboard_card>
                <.dashboard_card title="Start Time">
                  <div class="text-md text-gray-200">-</div>
                </.dashboard_card>
                <.dashboard_card title="Finish Time">
                  <div class="text-md text-gray-200">-</div>
                </.dashboard_card>
              </.dashboard_container>
              <.dashboard_container>
                <.dashboard_card title="Total Count of Messages" class="col-span-2">
                  <.kvp_entry>
                    <:key></:key>
                    <:value>Count</:value>
                  </.kvp_entry>
                  <%= for {type, count} <- @analysis.content["message_type_count"] do %>
                    <.kvp_entry>
                      <:key><%= type %></:key>
                      <:value><%= count %></:value>
                    </.kvp_entry>
                  <% end %>
                </.dashboard_card>
                <.dashboard_card title="Tables Impacted" class="col-span-2"></.dashboard_card>
              </.dashboard_container>
            <% else %>
              <.empty_state icon_name="presentation-chart-line">
                <:message>
                  No analysis has been run, please click the button below to queue the analysis.
                </:message>
                <:action>
                  <button
                    phx-click="perform_analysis"
                    class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-xs"
                  >
                    Perform Analysis
                  </button>
                </:action>
              </.empty_state>
            <% end %>
          </div>
        <% else %>
          <.empty_state icon_name="document-magnifying-glass">
            <:message>
              <div class="mb-4">Select a recording to view its analysis.</div>
              <div class="mb-2 text-xs">
                If you don't have any, you can start a recording
                <.link patch={~p"/"} class="text-blue-500 underline">here</.link>.
              </div>

            </:message>
          </.empty_state>
        <% end %>
      </:right_section>
    </.two_columns>
    """
  end

  def search_form(assigns) do
    ~H"""
    <div class="">
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
    """
  end

  def cards(assigns) do
    ~H"""
    <ul class="my-2 space-y-2">
      <%= for recording <- @recordings do %>
        <.card recording={recording} selected_file={@selected_file}></.card>
      <% end %>
    </ul>
    """
  end

  def card(assigns) do
    recording = assigns.recording
    selected_file = assigns.selected_file

    card_classes =
      if recording.file_name == selected_file.file_name do
        "text-white bg-blue-500 hover:bg-blue-500"
      else
        "bg-gray-800 hover:bg-gray-700"
      end

    text_classes =
      if recording.file_name == selected_file.file_name do
        "hover:bg-blue-500 text-blue-300"
      else
        "hover:bg-gray-700 text-gray-400"
      end

    assigns = assign(assigns, card_classes: card_classes, text_classes: text_classes)

    ~H"""
    <li>
      <div
        patch={~p"/analytics?#{[file_name: @recording.file_name]}"}
        class={"rounded-sm flex items-center space-x-2 #{@card_classes}"}
      >
        <.link
          patch={~p"/analytics?#{[file_name: @recording.file_name]}"}
          class="flex-1 p-3 whitespace-nowrap font-mono text-xs"
        >
          <div>
            <span class="font-semibold"><%= @recording.file_name %></span>
            <div class={"#{@text_classes} mt-2"}>
              <%= Timex.format!(@recording.creation_time, "{YYYY}-{0M}-{0D} {h24}:{m}:{s}") %>
            </div>
          </div>
        </.link>
        <div
          class={"rounded flex items-center justify-center #{@text_classes} hover:text-white cursor-pointer pr-3"}
          phx-click="delete_recording"
          phx-value-recording={@recording.file_name}
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

  def handle_event("perform_analysis", _params, socket) do
    file = socket.assigns.selected_file

    PgSiphonManagement.Analysis.Generator.call(file.full_path)

    {:noreply, assign(socket, in_progress: [file.file_name], analysis: nil)}
  end

  # Analysis has finished
  def handle_info({:complete, %{full_path: full_path}}, socket) do
    file_name = Path.basename(full_path)

    selected_file = Recordings.get_recording(file_name)
    {_, analysis} = Recordings.get_analysis(file_name)

    {:noreply,
     assign(
       socket,
       selected_file: selected_file,
       analysis: analysis,
       in_progress: List.delete(socket.assigns.in_progress, file_name)
     )}
  end

  # Recording has started
  def handle_info({:start, %{file_name: file_name}}, socket) do
    IO.puts("Recording has started: #{file_name}")

    {:noreply,
      assign(
        socket,
        recording: true
    )}
  end

  # Recording has finished
  def handle_info({:finish, %{file_name: file_name}}, socket) do
    IO.puts("Recording has finished: #{file_name}")

    {:noreply,
    assign(
      socket,
        recording: false
    )}
  end
end
