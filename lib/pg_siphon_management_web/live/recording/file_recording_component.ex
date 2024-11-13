defmodule PgSiphonManagementWeb.Recording.FileRecordingComponent do
  use PgSiphonManagementWeb, :live_component

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= @selected_file.full_path %>
    </div>
    """
  end
end
