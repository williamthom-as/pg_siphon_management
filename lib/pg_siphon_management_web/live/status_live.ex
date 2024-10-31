defmodule PgSiphonManagementWeb.StatusLive do
  use PgSiphonManagementWeb, :live_view

  @max_display_records 500

  alias PgSiphonManagementWeb.ActiveConnectionsComponent
  alias PgSiphonManagementWeb.ExporterComponent
  alias PgSiphon.ActiveConnectionsServer

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(:broadcaster, "message_frames")
    end

    %{recording: recording} = :sys.get_state(:query_server)
    %{filter_message_types: filter_message_types} = :sys.get_state(:monitoring_server)
    proxy_config = :sys.get_state(:proxy_server)
    active_connections = ActiveConnectionsServer.get_active_connections()

    socket =
      socket
      |> stream(:messages, [])
      |> assign(counter: 0)
      |> assign(recording: recording)
      |> assign(proxy_config: proxy_config)
      |> assign(filter_message_types: filter_message_types)
      |> assign(active_connections: active_connections)
      |> assign(accordion_open: %{"monitoring_settings" => true, "active_connections" => false})

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
              title="Message Types"
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
                      <span class="text-gray-300">[<%= key %>]</span>

                      <% is_on = Enum.member?(@filter_message_types, key) %>
                      <input
                        type="checkbox"
                        class="form-checkbox h-5 w-5 text-blue-600 bg-gray-800 border-gray-600 focus:ring-blue-500 cursor-pointer"
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
          <.accordion_entry title="Record Session">
            <.live_component module={ExporterComponent} id={:exporter} />
          </.accordion_entry>
          <.accordion_entry title="Active Connections" open={@accordion_open["active_connections"]}>
            <.live_component
              module={ActiveConnectionsComponent}
              id={:active_conns}
              active_connections={@active_connections}
            />
          </.accordion_entry>
        </.accordion_container>
      </:left_section>
      <:right_section>
        <%!-- Move this to live component later  --%>
        <div class="mx-auto border-gray-700">
          <div class="bg-gray-800 rounded-t-sm px-4 py-2 flex items-center justify-between">
            <div class="text-gray-400 text-xs font-mono"></div>
            <span class="text-gray-400 text-xs font-mono">
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
            class="bg-black text-white p-4 rounded-b-sm min-h-96 overflow-y-auto font-mono text-xs flex-grow max-h-[calc(100vh-100px)]"
            phx-hook="ScrollToBottom"
          >
            <div :for={{id, message} <- @streams.messages} id={id} class="mb-2">
              <p>
                <span class="text-blue-400">
                  [<%= message.time %>]
                </span>
                <span class="text-green-400">[<%= message.message.type %>]</span>
                <%= message.message.payload %>
              </p>
            </div>
          </div>
        </div>
      </:right_section>
    </.two_columns>
    """
  end

  def handle_event("toggle_filter_message_type", %{"key" => key, "value" => "on"}, socket) do
    PgSiphon.MonitoringServer.add_filter_type(key)
    {:noreply, socket}
  end

  def handle_event("toggle_filter_message_type", %{"key" => key}, socket) do
    PgSiphon.MonitoringServer.remove_filter_type(key)
    {:noreply, socket}
  end

  def handle_info(:refresh_connections, socket) do
    {:noreply, assign_connections(socket)}
  end

  @spec handle_info({:new_message_frame, map()}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:new_message_frame, message}, socket) do
    counter = socket.assigns.counter

    formatted_time =
      DateTime.utc_now()
      |> Calendar.strftime("%Y-%m-%d %H:%M:%S:%f")

    socket =
      socket
      |> stream_insert(:messages, %{id: counter, time: formatted_time, message: message, at: 0})
      |> handle_overflow(counter)

    {:noreply, assign(socket, counter: counter + 1)}
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

  @spec handle_overflow(Phoenix.LiveView.Socket.t(), non_neg_integer()) ::
          Phoenix.LiveView.Socket.t()
  defp handle_overflow(socket, counter) do
    cond do
      counter >= @max_display_records ->
        # this returns updated socket
        stream_delete_by_dom_id(socket, :messages, "messages-#{counter - @max_display_records}")

      true ->
        socket
    end
  end

  defp assign_connections(socket) do
    socket
    |> assign(active_connections: ActiveConnectionsServer.get_active_connections())
    |> assign(accordion_open: %{socket.assigns.accordion_open | "active_connections" => true})
  end
end
