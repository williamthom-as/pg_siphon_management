defmodule PgSiphonManagementWeb.LayoutComponents do
  use Phoenix.Component

  slot :inner_block, required: true
  attr :tooltip, :string, default: ""
  attr :href, :string

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
end
