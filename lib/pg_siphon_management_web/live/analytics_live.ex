defmodule PgSiphonManagementWeb.AnalyticsLive do
  use PgSiphonManagementWeb, :live_view

  alias PgSiphonManagement.Recordings

  def mount(_params, _session, socket) do
    recordings = Recordings.list_recordings()

    IO.inspect(recordings)

    socket =
      assign(
        socket,
        recordings: recordings
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.two_columns>
      <:left_section>
        <div class="w-full rounded-sm shadow">
          <h5 class="mb-4 text-base font-mono text-sm text-gray-200">
            Recorded Logs
          </h5>
          <ul class="my-2 space-y-2">
            <%= for recording <- @recordings do %>
              <li>
                <a
                  href="#"
                  class="flex items-center p-3 text-base rounded-sm group hover:shadow text-gray-200 bg-gray-800 hover:bg-gray-700 border border-gray-800"
                >
                  <div class="flex-1 whitespace-nowrap text-sm">
                    <span class="font-semibold"><%= recording.file %></span>
                    <div class="text-gray-400">
                      <%= Timex.format!(recording.creation_time, "{YYYY}-{0M}-{0D} {h24}:{m}:{s}") %>
                    </div>
                  </div>
                  <span class="inline-flex items-center justify-center px-2 py-0.5 ms-3 text-xs font-medium rounded bg-green-500 text-white">
                    Ready
                  </span>
                </a>
              </li>
            <% end %>
          </ul>
        </div>
      </:left_section>
      <:right_section></:right_section>
    </.two_columns>
    """
  end
end
