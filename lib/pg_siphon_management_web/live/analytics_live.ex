defmodule PgSiphonManagementWeb.AnalyticsLive do
  use PgSiphonManagementWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="p-4">
      <h1 class="text-2xl font-semibold text-gray-300">Analytics</h1>
      <p class="text-gray-500 text-sm mt-2">This is the analytics page.</p>
    </div>
    """
  end
end
