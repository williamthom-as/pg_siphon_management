defmodule PgSiphonManagementWeb.QueryBreakdownLive do
  use PgSiphonManagementWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      Query Breakdown
    </div>
    """
  end
end
