defmodule PgSiphonManagementWeb.LayoutComponents do
  use Phoenix.Component

  @doc """
  Renders a sidebar with a slot for navigation links.

  ## Example

  <.sidebar>
    <.nav_link href={~p"/"} tooltip="Home">
      <Heroicons.icon name="home" type="mini" class="h-4 w-4" />
    </.nav_link>
    <.nav_link href={~p"/status"} tooltip="Live">
      <Heroicons.icon name="bars-4" type="mini" class="h-4 w-4" />
    </.nav_link>
  </.sidebar>
  """
  slot :nav_links, required: true
  slot :bottom_links, required: false

  def sidebar(assigns) do
    ~H"""
    <div class="w-10 bg-gray-900 text-white flex flex-col items-center border-r border-gray-800">
      <div class="p-2 pt-3 text-center text-sm font-mono font-semibold [writing-mode:vertical-lr] bg-gradient-to-b from-blue-500 to-purple-500 text-transparent bg-clip-text">
        PgSiphon
      </div>
      <nav class="flex-1 px-4 py-4 space-y-2">
        <%= render_slot(@nav_links) %>
      </nav>
      <div class="flex-3 px-4 py-4 space-y-2">
        <%= render_slot(@bottom_links) %>
      </div>
    </div>
    """
  end

  @doc """
  Renders a top bar with three slots: left, center, and right.

  ## Example

  <.topbar>
    <:left_slot>
      Left content
    </:left_slot>
    <:center_slot>
      Center content
    </:center_slot>
    <:right_slot>
      Right content
    </:right_slot>
  </.topbar>
  """
  slot :left_slot, required: false
  slot :center_slot, required: false
  slot :right_slot, required: false

  def topbar(assigns) do
    ~H"""
    <div class="w-full h-10 bg-gray-900 text-gray-800 flex border-b border-gray-800">
      <div class="flex-1 flex items-center justify-start">
        <div class="pl-4 p-2 text-center text-xs font-mono">
          <%= render_slot(@left_slot) %>
        </div>
      </div>
      <div class="flex-1 flex items-center justify-center">
        <div class="p-2 text-center text-xs font-mono">
          <%= render_slot(@center_slot) %>
        </div>
      </div>
      <div class="flex-1 flex items-center justify-end">
        <div class="pr-4 p-2 text-center text-xs font-mono">
          <%= render_slot(@right_slot) %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a split layout with two sections: left and right.

  ## Example

  <.two_columns>
    <:left_section>
      --left--
    </:left_section>
    <:right_section>
      --right--
    </:right_section>
  </.two_columns>
  """
  slot :left_section, required: true
  slot :right_section, required: true

  def two_columns(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row h-full">
      <div class="w-full md:w-1/3 md:max-w-lg bg-gray-900 text-gray-200 p-3">
        <%= render_slot(@left_section) %>
      </div>
      <div class="w-full md:w-2/3 bg-gray-900/70 p-3 flex-grow">
        <%= render_slot(@right_section) %>
      </div>
    </div>
    """
  end

  @doc """
  Renders an accordion container.

  ## Example

  <.accordion_container id="accordion">
    <.accordion_entry title="title">
      <p>content</p>
    </.accordion_entry>
  </.accordion_container>
  """
  attr :id, :string, required: true
  slot :inner_block, required: true

  def accordion_container(assigns) do
    ~H"""
    <div id={@id} phx-hook="Accordion">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders an accordion entry with a title and inner block.

  ## Example

  <.accordion_entry title="title">
    <p>content</p>
  </.accordion_entry>
  """
  attr :title, :string, required: true
  attr :open, :boolean, default: false
  slot :inner_block, default: ""

  def accordion_entry(assigns) do
    ~H"""
    <div class="border border-gray-700 mb-2">
      <button class="accordion-header w-full text-left p-2 bg-gray-800 text-gray-200 hover:bg-gray-700 font-mono text-xs flex justify-between items-center">
        <div class="flex items-center">
          <Heroicons.icon name="ellipsis-vertical" type="mini" class="h-3 w-3" />
          <span class="ml-2">
            <%= @title %>
          </span>
        </div>
        <svg
          class="chevron w-4 h-4 transition-transform duration-300 ease-out"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7">
          </path>
        </svg>
      </button>
      <div class={"accordion-content bg-gray-900 text-gray-300 font-mono text-sm #{if @open, do: "open", else: ""}"}>
        <div class="p-2">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a key-value pair row.

  ## Example

  <.kvp_container title="Proxy Settings">
    <.kvp_entry>
      <:key>Host Addr:</:key>
      <:value><%= @proxy_config.to_host %></:value>
    </.kvp_entry>
    <.kvp_entry>
      <:key>Host Port:</:key>
      <:value><%= @proxy_config.to_port %></:value>
    </.kvp_entry>
  </.kvp_container>
  """

  attr :title, :string, required: true
  attr :tooltip, :string, default: ""
  slot :inner_block, required: true

  def kvp_container(assigns) do
    ~H"""
    <div class="bg-gray-900 p-2 shadow-md mb-2">
      <h3 class="text-gray-300 text-sm mb-2" title={@tooltip}><%= @title %></h3>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a key-value pair entry.

  ## Example

  <.kvp_entry>
    <:key>Host Addr:</key>
    <:value>localhost</value>
  </.kvp_entry>
  """

  slot :key, required: true
  slot :value, required: true

  def kvp_entry(assigns) do
    ~H"""
    <div class="flex justify-between items-center mb-2">
      <span class="text-gray-400 text-xs"><%= render_slot(@key) %></span>
      <span class="text-gray-300"><%= render_slot(@value) %></span>
    </div>
    """
  end
end
