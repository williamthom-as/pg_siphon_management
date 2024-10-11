defmodule PgSiphonManagementWeb.StatusLive do
  use PgSiphonManagementWeb, :live_view

  def mount(_params, _session, socket) do
    %{recording: recording} = :sys.get_state(:query_server)

    socket = assign(socket, :recording, recording)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
      <h1>Status</h1>
      <%= @recording %>
    """
  end

end
