defmodule PgSiphonManagementWeb.UtilityComponents do
  use Phoenix.Component

  slot :inner_block, required: true
  attr :tooltip, :string, default: ""
  attr :href, :string

  @doc """
  Displays a navigation link.

  ## Examples
      <.nav_link href="/status" tooltip="Status">Status</.nav_link>
      <.nav_link href="/settings" tooltip="Settings">Settings</.nav_link>
  """

  def nav_link(assigns) do
    ~H"""
    <div class="relative group">
      <a
        href={@href}
        class="block p-2 rounded hover:bg-gray-700 flex items-center justify-center text-gray-400 hover:text-white"
      >
        <%= render_slot(@inner_block) %>
      </a>
      <div class="absolute bg-opacity-75 left-full top-1/2 transform -translate-y-1/2 ml-2 hidden group-hover:block bg-gray-700 text-white text-xs rounded py-1 px-2 whitespace-nowrap">
        <%= @tooltip %>
      </div>
    </div>
    """
  end

  @doc """
  Displays a badge.

  ## Examples
      <.badge colour="red">Status: Down</.badge>
      <.badge colour="green">Status: Up</.badge>
      <.badge colour="blue">Status: Up</.badge>
  """
  attr :colour, :string, required: true, doc: "the colour of the badge, can be any tailwind color"
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={"badge bg-#{@colour}-500 text-white px-2 py-1 rounded"}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  @doc """
  Displays an alert bar.

  ## Examples
      <.alert_bar type="success">This is a success message.</.alert_bar>
      <.alert_bar type="danger">This is a danger message.</.alert_bar>
      <.alert_bar type="primary">This is a primary message.</.alert_bar>
  """
  attr :type, :string,
    required: true,
    doc: "the type of the alert, can be success, danger, primary"

  attr :title, :string, default: ""
  slot :inner_block, required: true

  def alert_bar(assigns) do
    ~H"""
    <div class={alert_class(@type)}>
      <div class="flex justify-between items-center">
        <%= if @title != "" do %>
          <div class="font-semibold"><%= @title %></div>
        <% end %>
        <div class="ml-2 text-xs"><%= render_slot(@inner_block) %></div>
      </div>
    </div>
    """
  end

  defp alert_class("success"), do: "bg-green-500 text-white p-4 rounded-lg shadow-md mb-4"
  defp alert_class("danger"), do: "bg-red-500 text-white p-4 rounded-lg shadow-md mb-4"
  defp alert_class("primary"), do: "bg-blue-500 text-white p-4 rounded-lg shadow-md mb-4"
  defp alert_class(_), do: "bg-gray-500 text-white p-4 rounded-lg shadow-md mb-4"
end
