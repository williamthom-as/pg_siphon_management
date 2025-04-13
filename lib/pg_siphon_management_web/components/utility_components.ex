defmodule PgSiphonManagementWeb.UtilityComponents do
  use Phoenix.Component

  slot :inner_block, required: false
  attr :tooltip, :string, default: ""
  attr :href, :string
  attr :route, :atom
  attr :current_path, :string
  attr :icon, :string
  attr :class, :string, default: ""

  @doc """
  Displays a navigation link.

  ## Examples
      <.nav_link href="/status" tooltip="Status" class="custom-class">Status</.nav_link>
      <.nav_link href="/settings" tooltip="Settings" class="custom-class">Settings</.nav_link>
  """

  def nav_link(assigns) do
    ~H"""
    <div class="relative group">
      <a
        href={@href}
        class={
          "block p-1.5 rounded hover:bg-gray-200 dark:hover:bg-gray-700 flex items-center justify-center text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-white #{if @current_path == @route, do: "bg-gray-100 dark:bg-gray-800", else: ""}"
        }
      >
        <Heroicons.icon
          name={@icon}
          type="outline"
          class={"h-4 w-4 #{if @current_path == @route, do: "text-blue-600 dark:text-purple-500", else: ""}"}
        />
        <%= render_slot(@inner_block) %>
      </a>
      <div class="absolute bg-opacity-75 left-full top-1/2 transform -translate-y-1/2 ml-2 hidden group-hover:block bg-gray-200 dark:bg-gray-700 text-gray-800 dark:text-white text-xs rounded py-1 px-2 whitespace-nowrap">
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
    <span class={"badge bg-gradient-to-br from-#{@colour}-500 to-#{@colour}-700 text-white px-2 py-1 rounded"}>
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

  defp alert_class("success"),
    do: "bg-gradient-to-br from-green-500 to-green-700 text-white p-4 rounded-md shadow-md"

  defp alert_class("danger"),
    do: "bg-gradient-to-br from-red-500 to-red-700 text-white p-4 rounded-md shadow-md"

  defp alert_class("primary"),
    do: "bg-gradient-to-br from-violet-500 to-violet-700 text-white p-4 rounded-md shadow-md"

  defp alert_class("info"),
    do: "bg-gradient-to-br from-blue-500 to-violet-700 text-white p-4 rounded-md shadow-md"

  defp alert_class(_),
    do: "bg-gradient-to-br from-gray-500 to-gray-700 text-white p-4 rounded-md shadow-md"

  attr :timestamp, :integer, required: true
  attr :class, :string, default: ""
  attr :date_time_format, :string, default: "{YYYY}-{0M}-{0D} {h24}:{m}:{s}"
  attr :show_time_ago, :boolean, default: true

  def format_ts(%{timestamp: nil} = assigns) do
    ~H"""
    <div></div>
    """
  end

  def format_ts(assigns) do
    converted_time =
      assigns.timestamp
      |> Timex.from_unix(:milliseconds)
      |> Timex.Timezone.convert(:local)

    formatted_timestamp =
      converted_time
      |> Timex.format!(assigns.date_time_format)

    time_ago =
      converted_time
      |> Timex.diff(Timex.now(), :duration)
      |> Timex.format_duration(:humanized)

    assigns =
      assigns
      |> assign(:formatted_timestamp, formatted_timestamp)
      |> assign(:time_ago, time_ago)

    ~H"""
    <span class={[@class, "block text-gray-300 dark:text-gray-700"]}>
      <span class="text-gray-700 dark:text-gray-300"><%= @formatted_timestamp %></span>
      <%= if @show_time_ago do %>
        <br />
        <small class="text-sm text-gray-500"><%= @time_ago %> ago</small>
      <% end %>
    </span>
    """
  end
end
