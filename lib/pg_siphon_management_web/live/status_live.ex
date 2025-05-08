defmodule PgSiphonManagementWeb.StatusLive do
  use PgSiphonManagementWeb, :live_view

  alias PgSiphonManagementWeb.ActiveConnectionsComponent
  alias PgSiphonManagementWeb.ExporterComponent
  alias PgSiphon.ActiveConnectionsServer
  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(:broadcaster, "message_frames")
      PubSub.subscribe(:recording_notifier, "recording")
    end

    %{recording: file_recording} = :sys.get_state(:recording_server)

    %{filter_message_types: filter_message_types, recording: active_logging} =
      :sys.get_state(:monitoring_server)

    proxy_config = :sys.get_state(:proxy_server)
    active_connections = ActiveConnectionsServer.get_active_connections()

    socket =
      socket
      |> stream(:messages, [])
      |> assign(counter: 0)
      |> assign(file_recording: file_recording)
      |> assign(active_logging: active_logging)
      |> assign(proxy_config: proxy_config)
      |> assign(filter_message_types: filter_message_types)
      |> assign(active_connections: active_connections)
      |> assign(
        accordion_open: %{
          "monitoring_settings" => true,
          "active_connections" => false
        }
      )
      |> assign(page_title: "Proxy")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.two_columns>
      <:left_section>
        <.accordion_container id="accordion-status-page">
          <.accordion_entry title="Proxy Settings">
            <.kvp_container title="Proxy">
              <.kvp_entry>
                <:key>Addr:</:key>
                <:value><%= @proxy_config.to_host %></:value>
              </.kvp_entry>
              <.kvp_entry>
                <:key>Port:</:key>
                <:value><%= @proxy_config.from_port %></:value>
              </.kvp_entry>
              <.kvp_entry>
                <:key>Status:</:key>
                <:value>
                  <%= if @proxy_config.running do %>
                    <.badge colour="green">
                      <span class="font-mono text-xs">Running</span>
                    </.badge>
                  <% else %>
                    <.badge colour="red">
                      <span class="font-mono text-xs">Disconnected</span>
                    </.badge>
                  <% end %>
                </:value>
              </.kvp_entry>
            </.kvp_container>
            <.kvp_container title="Host">
              <.kvp_entry>
                <:key>Addr:</:key>
                <:value><%= @proxy_config.to_host %></:value>
              </.kvp_entry>
              <.kvp_entry>
                <:key>Port:</:key>
                <:value><%= @proxy_config.to_port %></:value>
              </.kvp_entry>
            </.kvp_container>
          </.accordion_entry>
          <.accordion_entry title="Monitoring Settings" open={@accordion_open["monitoring_settings"]}>
            <.kvp_container
              title="Message Types (Front End)"
              tooltip="If no types are selected, all message frame types are displayed."
            >
              <div class="text-gray-600 text-xs mb-2">
                <span class="font-semibold">Note:</span>
                If no types are selected, all message frame types are displayed.
              </div>
              <%= for {key, value} <- PgSiphon.Message.get_fe_message_types() do %>
                <.kvp_entry>
                  <:key><%= value %></:key>
                  <:value>
                    <label class="flex items-center space-x-3 cursor-pointer">
                      <span class="text-gray-500">[<%= key %>]</span>

                      <% is_on = Enum.member?(@filter_message_types, key) %>
                      <input
                        type="checkbox"
                        class="form-checkbox h-5 w-5 text-blue-500 bg-white border-gray-300 dark:bg-gray-800 dark:border-gray-600 focus:ring-blue-500 cursor-pointer"
                        checked={is_on}
                        phx-click="toggle_filter_message_type"
                        phx-value-key={key}
                      />
                    </label>
                  </:value>
                </.kvp_entry>
              <% end %>
              <div class="flex space-x-2 mt-4">
                <button class="border border-gray-500 text-gray-500 hover:bg-gray-500 hover:text-white font-semibold py-1 px-2 rounded w-full text-xs">
                  None
                </button>
                <button class="border border-blue-500 text-blue-500 hover:bg-blue-500 hover:text-white font-semibold py-1 px-2 rounded w-full text-xs">
                  All
                </button>
              </div>
            </.kvp_container>
          </.accordion_entry>
          <.accordion_entry title="Active Connections" open={@accordion_open["active_connections"]}>
            <.live_component
              module={ActiveConnectionsComponent}
              id={:active_conns}
              active_connections={@active_connections}
            />
          </.accordion_entry>
          <.accordion_entry title="Record Session">
            <.live_component module={ExporterComponent} id={:exporter} />
          </.accordion_entry>
        </.accordion_container>
      </:left_section>
      <:right_section>
        <%= if @file_recording do %>
          <div class="pb-3">
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
        <%= if @active_logging == false do %>
          <div class="pb-3">
            <.alert_bar type="info">
              <div class="flex flex-row justify-start items-center space-x-4">
                <Heroicons.icon name="pause" type="outline" class="h-6 w-6" />
                <span class="font-mono text-xs">
                  Active logging is paused, messages will not be shown or recorded.
                </span>
              </div>
            </.alert_bar>
          </div>
        <% end %>
        <%!-- move this to live component later  --%>
        <div class="mx-auto border border-gray-300 dark:border-gray-700">
          <div class="bg-gray-200/50 dark:bg-gray-800 rounded-t-sm p-2 flex items-center justify-between">
            <div class="flex items-center space-x-2">
              <%= if @active_logging do %>
                <button
                  phx-click="stop_active_logging"
                  class="border border-gray-400 dark:border-gray-600 text-gray-500 dark:text-gray-400 hover:border-indigo-500 dark:hover:border-indigo-500 hover:bg-indigo-500 hover:text-white py-1 px-2 rounded w-full text-xs transition-all duration-300 flex items-center justify-center gap-2 dark:hover:text-white"
                >
                  <Heroicons.icon name="pause" type="outline" class="h-4 w-4" />
                  <span>Pause</span>
                </button>
              <% else %>
                <button
                  phx-click="start_active_logging"
                  class="border border-gray-400 dark:border-gray-600 text-gray-500 dark:text-gray-400 hover:border-blue-500 dark:hover:border-blue-500 hover:bg-blue-500 hover:text-white py-1 px-2 rounded w-full text-xs transition-all duration-300 flex items-center justify-center gap-2 dark:hover:text-white"
                >
                  <Heroicons.icon name="play" type="outline" class="h-4 w-4" />
                  <span>Start</span>
                </button>
              <% end %>
              <button
                phx-click="clear_console"
                class="border border-gray-400 dark:border-gray-600 text-gray-500 dark:text-gray-400 py-1 px-2 rounded w-full text-xs transition-colors duration-300 flex items-center justify-center gap-2 dark:hover:border-red-500 hover:bg-red-500 hover:border-red-500 hover:text-white dark:hover:text-white"
              >
                <Heroicons.icon name="trash" type="outline" class="h-4 w-4" />
                <span>Clear</span>
              </button>
            </div>
            <span class="text-gray-600 dark:text-gray-400 text-xs font-mono">
              Logging:
              <%= if Enum.empty?(@filter_message_types) do %>
                All
              <% else %>
                <%= Enum.join(@filter_message_types, ", ") %>
              <% end %>
              [<%= @counter %>]
            </span>
          </div>
          <div
            id="messages-window"
            phx-update="stream"
            class="bg-white dark:bg-black text-gray-800 dark:text-white p-4 rounded-b-sm min-h-96 overflow-y-auto font-mono text-xs flex-grow max-h-[calc(100vh-240px)]"
            phx-hook="ScrollToBottom"
          >
            <div :for={{id, message} <- @streams.messages} id={id} class="mb-2">
              <p>
                <span class="text-blue-600 dark:text-blue-400">
                  [<%= message.message.time %>]
                </span>
                <span class="text-green-600 dark:text-green-400">
                  [<%= message.message.type %>]
                </span>
                <span class="break-all">
                  <%= case message.message.type do %>
                    <% "P" -> %>
                      <% prep_statement = message.message.extras[:prepared_statement] %>
                      <%= if !Enum.empty?(prep_statement) do %>
                        <span class="text-red-600 dark:text-red-400">
                          [<%= prep_statement %>]
                        </span>
                      <% end %>

                      <span class="text-gray-800 dark:text-slate-200">
                        <%= message.message.payload %>
                      </span>
                    <% "B" -> %>
                      <% extras = message.message.extras %>
                      <%= if extras[:statement_name] != "" do %>
                        <span class="text-red-600 dark:text-red-400">
                          [Stmt: <%= extras[:statement_name] %>]
                        </span>
                      <% end %>
                      <span class="text-fuchsia-600 dark:text-fuchsia-400">
                        Params (<%= extras[:param_count] %>):
                      </span>
                      <%= if Map.has_key?(extras, :param_vals) do %>
                        <%= for value <- extras[:param_vals] do %>
                          <span class="text-yellow-600 dark:text-yellow-400">
                            [<%= List.last(value) %>]
                          </span>
                        <% end %>
                      <% end %>
                    <% _ -> %>
                      <span class="text-gray-800 dark:text-slate-100">
                        <%= message.message.payload %>
                      </span>
                  <% end %>
                </span>
              </p>
            </div>
          </div>
        </div>
      </:right_section>
    </.two_columns>
    """
  end

  def handle_event("start_active_logging", _params, socket) do
    PgSiphon.MonitoringServer.set_recording(true)

    {:noreply,
     assign(socket,
       active_logging: true
     )}
  end

  def handle_event("stop_active_logging", _params, socket) do
    PgSiphon.MonitoringServer.set_recording(false)

    {:noreply,
     assign(socket,
       active_logging: false
     )}
  end

  def handle_event("toggle_filter_message_type", %{"key" => key, "value" => "on"}, socket) do
    PgSiphon.MonitoringServer.add_filter_type(key)
    {:noreply, socket}
  end

  def handle_event("toggle_filter_message_type", %{"key" => key}, socket) do
    PgSiphon.MonitoringServer.remove_filter_type(key)
    {:noreply, socket}
  end

  def handle_event("clear_console", _params, socket) do
    socket =
      socket
      |> stream(:messages, [], reset: true)
      |> assign(counter: 0)

    {:noreply, put_flash(socket, :info, "Console has been cleared")}
  end

  def handle_info(:refresh_connections, socket) do
    {:noreply, assign_connections(socket)}
  end

  @spec handle_info({:new_message_frame, list(map())}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:new_message_frame, messages}, socket) do
    initial_counter = socket.assigns.counter

    {messages_ids, final_counter} =
      Enum.reduce(messages, {[], initial_counter}, fn message, {acc, counter} ->
        {[%{id: counter, message: message} | acc], counter + 1}
      end)

    socket =
      socket
      |> stream(:messages, Enum.reverse(messages_ids))

    # |> handle_overflow(final_counter)

    {:noreply, assign(socket, counter: final_counter)}
  end

  @spec handle_info({:connections_changed}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:connections_changed}, socket) do
    {:noreply, assign_connections(socket)}
  end

  @spec handle_info(:clear_expired_connections, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info(:clear_expired_connections, socket) do
    {:noreply, assign_connections(socket)}
  end

  @spec handle_info({:message_types_changed, list()}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:message_types_changed, types}, socket) do
    {:noreply, assign(socket, filter_message_types: types)}
  end

  def handle_info({:start_export, %{file_name: file_name}}, socket) do
    {:noreply, assign(socket, file_recording: true, file_name: file_name)}
  end

  # Recording has started
  def handle_info({:start, %{file_name: file_name}}, socket) do
    {:noreply, assign(socket, file_recording: true, file_name: file_name)}
  end

  # Recording has finished
  def handle_info({:finish, %{file_name: file_name}}, socket) do
    IO.puts("Recording has finished: #{file_name}")

    {:noreply,
     assign(
       socket,
       file_recording: false,
       file_name: nil
     )}
  end

  # @spec handle_overflow(Phoenix.LiveView.Socket.t(), non_neg_integer()) ::
  #         Phoenix.LiveView.Socket.t()
  # defp handle_overflow(socket, counter) do
  #   cond do
  #     counter >= @max_display_records ->
  #       start_id = counter - @max_display_records

  #       remove_ids =
  #         0..start_id
  #         |> Enum.map(fn id -> "messages-#{id}" end)

  #       # reduce with socket acc
  #       Enum.reduce(remove_ids, socket, fn id, acc ->
  #         stream_delete_by_dom_id(acc, :messages, id)
  #       end)

  #     true ->
  #       socket
  #   end
  # end

  defp assign_connections(socket) do
    socket
    |> assign(active_connections: ActiveConnectionsServer.get_active_connections())
    |> assign(accordion_open: %{socket.assigns.accordion_open | "active_connections" => true})
  end
end
