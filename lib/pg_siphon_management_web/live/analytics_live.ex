defmodule PgSiphonManagementWeb.AnalyticsLive do
  use PgSiphonManagementWeb, :live_view

  alias PgSiphonManagement.Recordings
  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(:recording_notifier, "recording")
      PubSub.subscribe(PgSiphonManagement.PubSub, "analysis")
    end

    card_list_options = %{
      offset: 0,
      max: 10,
      filter: nil
    }

    recording_list_options = %{
      offset: 0,
      max: 20,
      filter_types: []
    }

    # Recordings needs to do more lifting, returning simple structs to be updated.
    # These should hold - is being recorded, is in progress, has analysis.
    recordings = Recordings.list_recordings(card_list_options)
    recordings_total_count = Recordings.get_recording_total_count()

    %{recording: recording, file_name: recording_file_name} =
      :sys.get_state(:recording_server)

    socket =
      assign(
        socket,
        recordings: recordings,
        card_list_options: card_list_options,
        recording_list_options: recording_list_options,
        recordings_total_count: recordings_total_count,
        page_title: "Analytics",
        in_progress: [],
        recording: recording,
        recording_file_name: (recording_file_name || "") <> ".raw.csv"
      )

    {:ok, socket}
  end

  def handle_params(%{"file_name" => file_name}, _uri, socket) do
    recording_list_options = %{
      offset: 0,
      max: 20,
      filter_types: []
    }

    selected_file = Recordings.get_recording(file_name)
    {_, analysis} = Recordings.get_analysis(file_name, recording_list_options)

    {:noreply,
     assign(
       socket,
       selected_file: selected_file,
       analysis: analysis,
       recording_list_options: recording_list_options
     )}
  end

  def handle_params(%{}, _uri, socket) do
    {selected_file, analysis} = get_first_selected_file(socket)

    {:noreply,
     assign(
       socket,
       selected_file: selected_file,
       analysis: analysis
     )}
  end

  def render(assigns) do
    ~H"""
    <.alerts recording={@recording} in_progress={@in_progress}></.alerts>
    <.two_columns>
      <:left_section>
        <div class="w-full rounded-sm shadow font-mono">
          <h5 class="mb-4 text-base font-mono text-md text-gray-200">
            Recorded Logs
          </h5>
          <.search_form options={@card_list_options}></.search_form>
          <.cards
            recordings={@recordings}
            selected_file={@selected_file}
            recording_file_name={@recording_file_name}
          >
          </.cards>
          <.search_footer options={@card_list_options} total_count={@recordings_total_count}></.search_footer>
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
                <.dashboard_card title="Start">
                  <div class="text-md text-gray-200">
                    <.format_ts timestamp={@analysis.content["start_time"]} />
                  </div>
                </.dashboard_card>
                <.dashboard_card title="Finish">
                  <div class="text-md text-gray-200">
                    <.format_ts timestamp={@analysis.content["end_time"]} />
                  </div>
                </.dashboard_card>
                <.dashboard_card title="Duration (sec)">
                  <div class="text-md text-gray-200">
                    <%= @analysis.content["duration"] %>
                  </div>
                </.dashboard_card>
                <.dashboard_card title="Total Count of Messages">
                  <div class="text-md text-gray-200">
                    <%= @analysis.content["total_count"] %>
                  </div>
                </.dashboard_card>
              </.dashboard_container>
              <.dashboard_container base_colspan={3}>
                <.dashboard_card title="Message Types" class="col-span-1">
                  <div class="font-mono text-gray-500 text-xs flex items-center mb-4">
                    <Heroicons.icon name="information-circle" type="mini" class="h-4 w-4 mr-2" />
                    Note: You can filter the replay log by toggling the message types.
                  </div>
                  <%= for {type, count} <- @analysis.content["message_type_count"] do %>
                    <.kvp_entry>
                      <:key>
                        <% msg_colour = PgMsgColourMapper.call(type) %>
                        <% full_name = PgSiphon.Message.get_name_for_message_type(type) %>
                        <span class={"text-#{msg_colour}-400 text-xs font-mono"}>
                          <%= full_name %> [<%= type %>]
                        </span>
                      </:key>
                      <:value>
                        <% is_on = Enum.member?(@recording_list_options.filter_types, type) %>
                        <label class="flex items-center space-x-3 cursor-pointer">
                          <span class="text-gray-300"><%= count %></span>

                          <input
                            type="checkbox"
                            class="form-checkbox h-5 w-5 text-blue-500 bg-gray-800 border-gray-600 focus:ring-blue-500 cursor-pointer"
                            checked={is_on}
                            phx-click="toggle_filter_message_type"
                            phx-value-key={type}
                          />
                        </label>
                      </:value>
                    </.kvp_entry>
                  <% end %>
                </.dashboard_card>
                <.dashboard_card title="Operations" class="col-span-1">
                  <%= for {type, count} <- @analysis.content["operations"] do %>
                    <.kvp_entry>
                      <:key>
                        <span class={"text-blue-400 text-xs font-mono"}>
                          <%= type %>
                        </span>
                      </:key>
                      <:value>
                        <%= count %>
                      </:value>
                    </.kvp_entry>
                  <% end %>
                </.dashboard_card>
                <.dashboard_card title="Tables" class="col-span-1">
                  <%= for {type, count} <- @analysis.content["tables"] do %>
                    <.kvp_entry>
                      <:key>
                        <span class={"text-blue-400 text-xs font-mono"}>
                          <%= type %>
                        </span>
                      </:key>
                      <:value>
                        <%= count %>
                      </:value>
                    </.kvp_entry>
                  <% end %>
                </.dashboard_card>
              </.dashboard_container>
              <.dashboard_container>
                <.dashboard_card title="Replay Log" class="col-span-4">
                  <.live_component
                    module={PgSiphonManagementWeb.Recording.FileRecordingComponent}
                    analysis={@analysis}
                    options={@recording_list_options}
                    id="file_recording_viewer"
                  />
                </.dashboard_card>
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
                If you don't have any, you can start a recording <.link
                  patch={~p"/"}
                  class="text-blue-500 underline"
                >here</.link>.
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
      <div class="flex items-center gap-4">
        <div class="flex-1">
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
        <div class="w-16">
          <.input
            type="select"
            label="Max"
            name="max"
            value={@options.max}
            options={[1, 2, 10, 20, 50, 100]}
            phx-click="change_search_max"
          />
        </div>
      </div>
    </div>
    """
  end

  def search_footer(assigns) do
    ~H"""
      <div class="flex justify-between space-x-2 items-center mt-4">
        <%= if @total_count > 0 do %>
          <.button phx-click="search_pagination" phx-value-change="decrement">
            <div class="flex items-center">
              <Heroicons.icon name="chevron-double-left" type="mini" class="h-4 w-4" />
            </div>
          </.button>
          <.pagination_text
            start_page={@options.offset + 1}
            end_page={min(@options.max + @options.offset, @total_count)}
            total_count={@total_count}
          />
          <.button phx-click="search_pagination" phx-value-change="increment">
            <div class="flex items-center">
              <Heroicons.icon name="chevron-double-right" type="mini" class="h-4 w-4" />
            </div>
          </.button>
        <% end %>
      </div>
    """
  end

  def cards(assigns) do
    ~H"""
    <ul class="my-2 space-y-2">
      <%= if Enum.empty?(@recordings) do %>
        <.empty_state
          icon_name="exclamation-triangle"
          alert_message="No recordings found."
          text_size="text-sm"
        >
          <:message>&nbsp;</:message>
        </.empty_state>
      <% else %>
        <%= for recording <- @recordings do %>
          <.card
            recording={recording}
            selected_file={@selected_file}
            recording_file_name={@recording_file_name}
          >
          </.card>
        <% end %>
      <% end %>
    </ul>
    """
  end

  def card(assigns) do
    recording = assigns.recording
    selected_file = assigns.selected_file

    is_in_progress = assigns.recording_file_name == recording.file_name

    {card_classes, text_classes} =
      case {recording, selected_file} do
        {rec, selec} when is_nil(rec) or is_nil(selec) ->
          {
            "bg-gray-800 hover:bg-gray-700 border-gray-700",
            "hover:bg-gray-700 text-gray-400"
          }

        {rec, selec} when rec.file_name == selec.file_name ->
          {
            "text-white bg-blue-500 hover:bg-blue-500 border-blue-500",
            "hover:bg-blue-500 text-blue-300"
          }

        _ ->
          {
            "bg-gray-800 hover:bg-gray-700 border-gray-700",
            "hover:bg-gray-700 text-gray-400"
          }
      end

    assigns =
      assign(assigns,
        card_classes: card_classes,
        text_classes: text_classes,
        is_in_progress: is_in_progress
      )

    ~H"""
    <li>
      <div
        patch={~p"/analytics?#{[file_name: @recording.file_name]}"}
        class={"rounded-sm flex items-center space-x-2 #{@card_classes} border"}
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
        <%= if @is_in_progress do %>
          <div class="text-xs p-3">
            <.badge colour="red">
              <span class="font-mono text-xs">Recording</span>
            </.badge>
          </div>
        <% else %>
          <div
            class={"rounded flex items-center justify-center #{@text_classes} hover:text-white cursor-pointer pr-3"}
            phx-click="delete_recording"
            phx-value-file_name={@recording.file_name}
          >
            <Heroicons.icon name="trash" type="mini" class="h-4 w-4" />
          </div>
        <% end %>
      </div>
    </li>
    """
  end

  def alerts(assigns) do
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
    """
  end

  # Searching for recording
  def handle_event("search", %{"search" => search_param}, socket) do
    card_list_options = %{socket.assigns.card_list_options | filter: search_param}
    recordings = Recordings.list_recordings(card_list_options)

    {:noreply, assign(socket, recordings: recordings, card_list_options: card_list_options)}
  end

  # Button to delete recording
  def handle_event("delete_recording", %{"file_name" => file_name}, socket) do
    Recordings.delete_recording(file_name)

    {selected_file, analysis} = get_first_selected_file(socket)

    {:noreply,
     assign(
       socket,
       recordings: Recordings.list_recordings(socket.assigns.card_list_options),
       recordings_total_count: Recordings.get_recording_total_count(),
       selected_file: selected_file,
       analysis: analysis
     )}
  end

  # Button to trigger analysis
  def handle_event("perform_analysis", _params, socket) do
    file = socket.assigns.selected_file

    PgSiphonManagement.Analysis.Generator.call(file.full_path)

    {:noreply, assign(socket, in_progress: [file.file_name], analysis: nil)}
  end

  def handle_event("search_pagination", %{"change" => "decrement"}, socket) do
    options = socket.assigns.card_list_options

    options = %{
      options
      | offset: max(options.offset - options.max, 0)
    }

    assign_card_list(socket, options)
  end

  def handle_event("search_pagination", %{"change" => "increment"}, socket) do
    options = socket.assigns.card_list_options
    total_count = socket.assigns.recordings_total_count

    if options.offset + options.max < total_count do
      options = %{
        options
        | offset: options.offset + options.max
      }

      assign_card_list(socket, options)
    else
      {:noreply, socket}
    end
  end

  def handle_event("file_rec_pagination", %{"change" => "decrement"}, socket) do
    options = socket.assigns.recording_list_options

    options = %{
      options
      | offset: max(options.offset - options.max, 0)
    }

    assign_analysis(socket, options)
  end

  def handle_event("file_rec_pagination", %{"change" => "increment"}, socket) do
    options = socket.assigns.recording_list_options
    total_count = socket.assigns.analysis.content["total_count"]

    if options.offset + options.max < total_count do
      options = %{
        options
        | offset: options.offset + options.max
      }

      assign_analysis(socket, options)
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_filter_message_type", %{"key" => key, "value" => "on"}, socket) do
    options = socket.assigns.recording_list_options

    options =
      if key in options.filter_types do
        options
      else
        %{options | filter_types: [key | options.filter_types]}
      end

    assign_analysis(socket, options)
  end

  def handle_event("toggle_filter_message_type", %{"key" => key}, socket) do
    options = socket.assigns.recording_list_options
    options = %{options | filter_types: List.delete(options.filter_types, key)}

    assign_analysis(socket, options)
  end

  def handle_event("change_search_max", %{"value" => max}, socket) do
    options = socket.assigns.card_list_options
    options = %{options | max: String.to_integer(max)}

    assign_card_list(socket, options)
  end

  def handle_event("change_file_rec_max", %{"value" => max}, socket) do
    options = socket.assigns.recording_list_options
    options = %{options | max: String.to_integer(max)}

    assign_analysis(socket, options)
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
       recording: true,
       recording_file_name: file_name
     )}
  end

  # Recording has finished
  def handle_info({:finish, %{file_name: file_name}}, socket) do
    IO.puts("Recording has finished: #{file_name}")

    {:noreply,
     assign(
       socket,
       recording: false,
       recording_file_name: nil
     )}
  end

  # impl
  defp get_first_selected_file(socket) do
    selected_file =
      Enum.find(socket.assigns.recordings, fn recording ->
        recording.file_name != socket.assigns.recording_file_name
      end)

    {_, analysis} =
      case selected_file do
        nil -> {nil, nil}
        _ -> Recordings.get_analysis(selected_file.file_name)
      end

    {selected_file, analysis}
  end

  defp assign_analysis(socket, options) do
    {_, analysis} =
      Recordings.get_analysis(
        socket.assigns.selected_file.file_name,
        options
      )

    {:noreply,
     assign(
       socket,
       analysis: analysis,
       recording_list_options: options
     )}
  end

  defp assign_card_list(socket, options) do
    recordings = Recordings.list_recordings(options)

    {:noreply,
      assign(
        socket,
        recordings: recordings,
        card_list_options: options
    )}
  end
end
