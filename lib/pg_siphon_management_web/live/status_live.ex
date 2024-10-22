defmodule PgSiphonManagementWeb.StatusLive do
  use PgSiphonManagementWeb, :live_view

  @max_display_records 500

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(:broadcaster, "message_frames")
    end

    %{recording: recording} = :sys.get_state(:query_server)

    socket =
      socket
      |> stream(:messages, [])
      |> assign(recording: recording)
      |> assign(counter: 0)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.two_columns>
      <:left_section>
        <.accordion_container id="accordion-status-page">
          <.accordion_entry title="Proxy Settings">
            <input
              type="text"
              class="bg-transparent border border-gray-600 text-white placeholder-gray-500 rounded px-2 py-1 text-xs focus:outline-none focus:ring-2 focus:ring-blue-500 w-full"
              placeholder="Enter text here"
            />
          </.accordion_entry>
          <.accordion_entry title="Recording">
            Here 2!
          </.accordion_entry>
        </.accordion_container>
      </:left_section>
      <:right_section>
        <div class="mx-auto">
          <div class="bg-gray-800 rounded-t-lg px-4 py-2 flex items-center justify-between">
            <div class="flex space-x-2"></div>
            <span class="text-gray-400 text-xs font-mono">Logging: All [<%= @counter %>]</span>
          </div>
          <div
            id="messages-window"
            phx-update="stream"
            class="bg-black text-white p-4 rounded-b-lg h-96 overflow-y-auto font-mono text-xs"
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

  def handle_info({:notify, message}, socket) do
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

  defp handle_overflow(socket, counter) do
    cond do
      counter >= @max_display_records ->
        stream_delete_by_dom_id(socket, :messages, "messages-#{counter - @max_display_records}")

      true ->
        socket
    end
  end
end
