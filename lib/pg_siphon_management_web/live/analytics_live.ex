defmodule PgSiphonManagementWeb.AnalyticsLive do
  use PgSiphonManagementWeb, :live_view

  alias PgSiphonManagement.Recordings

  def mount(_params, _session, socket) do
    recordings = Recordings.list_recordings()

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
        <div class="font-mono">
          <h4>Recordings</h4>
        </div>
      </:left_section>
      <:right_section></:right_section>
    </.two_columns>
    """
  end
end
