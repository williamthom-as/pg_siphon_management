defmodule PgSiphonManagementWeb.FormComponents do
  use Phoenix.Component

  attr :type, :string, default: "text"
  attr :placeholder, :string, default: ""
  attr :value, :string, default: ""

  def f_input(assigns) do
    ~H"""
    <input
      type={@type}
      class="bg-transparent border border-gray-600 text-white placeholder-gray-500 rounded px-2 py-1 text-xs focus:outline-none focus:ring-2 focus:ring-blue-500 w-full"
      placeholder={@placeholder}
      value={@value}
    />
    """
  end

  attr :options, :list, required: true

  def select(assigns) do
    ~H"""
    <select class="bg-transparent border border-gray-600 text-white placeholder-gray-500 rounded px-2 py-1 text-xs focus:outline-none focus:ring-2 focus:ring-blue-500 w-full">
      <%= for {value, label} <- @options do %>
        <option value={value}><%= label %></option>
      <% end %>
    </select>
    """
  end
end
