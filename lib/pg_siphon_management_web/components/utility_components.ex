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
end
