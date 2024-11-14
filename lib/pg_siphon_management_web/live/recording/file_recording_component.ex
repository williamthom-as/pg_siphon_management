defmodule PgSiphonManagementWeb.Recording.FileRecordingComponent do
  use PgSiphonManagementWeb, :live_component

  alias PgSiphonManagement.Recording.FilterRecordingRequest

  def mount(socket) do
    {_, changeset} = FilterRecordingRequest.create(%{})

    {:ok,
     socket
     |> assign(form: to_form(changeset))}
  end

  def render(assigns) do
    ~H"""
    <div class="">
      <div class="flex justify-between items-center mb-4">
        <.form
          for={@form}
          id="recording-form"
          phx-submit="submit"
          phx-target={@myself}
          class="flex flex-col md:flex-row space-y-4 md:space-y-0 md:space-x-4"
        >
          <div class="flex flex-col md:flex-row space-y-4 md:space-y-0 md:space-x-4">
            <div class="w-16">
              <.input
                type="select"
                field={@form[:max]}
                value={@options.max}
                label="Max"
                options={[10, 20, 50, 100]}
                class="w-full"
              />
            </div>
          </div>
        </.form>
        <div class="flex justify-end space-x-4 items-center">
          <.pagination_text
            start_page={@options.offset + 1}
            end_page={min(@options.max + @options.offset, @analysis.content["total_count"])}
            total_count={@analysis.content["total_count"]}
          />
          <.button phx-click="pagination" phx-value-change="decrement">Previous</.button>
          <.button phx-click="pagination" phx-value-change="increment">Next</.button>
        </div>
      </div>
      <div class="overflow-auto">
        <div class="flex flex-col">
          <div class="flex flex-row bg-gray-900 p-2 mb-2 text-xs font-semibold font-mono rounded-sm text-center items-center text-gray-300">
            <div class="w-12 font-bold">Type</div>
            <div class="flex-1 font-bold ml-4">Message</div>
            <div class="w-24 font-bold">Timestamp</div>
          </div>
          <%= for {{_, [type, message, timestamp]}, idx} <- Enum.with_index(@analysis.replay_log) do %>
            <% msg_colour = PgMsgColourMapper.call(type) %>
            <div class={"flex flex-row p-2 py-1 text-gray-300 items-center-x #{if rem(idx, 2) == 0, do: "bg-gray-800", else: "bg-zinc-700 bg-opacity-30"}"}>
              <div class={"w-12 text-#{msg_colour}-400 text-xs text-center"}>[<%= type %>]</div>
              <div class="flex-1 overflow-auto font-mono text-xs leading-relaxed scrollbar-hide [&::-webkit-scrollbar]:hidden [-ms-overflow-style:none] [scrollbar-width:none]">
                <.sql_fmt message={message} />
              </div>
              <div class="w-24 text-gray-500 text-xs text-center">
                <%= timestamp %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def sql_fmt(assigns) do
    preformatted = assigns[:message]

    {:ok, formatted_sql} = SqlFmt.format_query(preformatted)

    assigns =
      assign(assigns,
        formatted_sql: formatted_sql
      )

    ~H"""
    <div class="max-h-96">
      <pre>
      <%= raw(@formatted_sql) %>
      </pre>
    </div>
    """
  end
end
