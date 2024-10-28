defmodule PgSiphonManagementWeb.ActiveConnectionsComponent do
  use PgSiphonManagementWeb, :live_component

  def mount(socket) do
    if connected?(socket) do
      :timer.send_interval(5_000, self(), :refresh_connections)
    end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-end">
        <button
          phx-click="refresh_connections"
          class="hover:text-gray-300 hover:bg-gray-700 p-2 rounded"
        >
          <Heroicons.icon name="arrow-path" type="outline" class="h-4 w-4" />
        </button>
      </div>
      <.kvp_container title="">
        <.kvp_entry :for={{{ip, port}, timestamp} <- @active_connections}>
          <:key>
            <div>
              <div class="text-gray-400 text-xs"><%= format_timestamp(timestamp) %></div>
              <div class="text-gray-500 text-xs"><%= time_ago_in_words(timestamp) %> ago</div>
            </div>
          </:key>
          <:value>
            <%= format_ip_addr(ip, port) %>
          </:value>
        </.kvp_entry>
      </.kvp_container>
    </div>
    """
  end

  defp format_ip_addr(ip, port) do
    "#{ip |> Tuple.to_list() |> Enum.join(".")}:#{port}"
  end

  defp format_timestamp(timestamp) do
    DateTime.from_unix!(timestamp) |> DateTime.to_string()
  end

  defp time_ago_in_words(timestamp) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, DateTime.from_unix!(timestamp), :second)

    cond do
      diff_seconds < 60 -> "#{diff_seconds} seconds"
      diff_seconds < 3600 -> "#{div(diff_seconds, 60)} minutes"
      diff_seconds < 86400 -> "#{div(diff_seconds, 3600)} hours"
      true -> "#{div(diff_seconds, 86400)} days"
    end
  end
end
