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
        <div class="flex flex-col md:flex-row space-y-4 md:space-y-0 md:space-x-4">
          <div class="w-16">
            <.input
              type="select"
              name="max"
              value={@options.max}
              label="Max"
              options={[10, 20, 50, 100]}
              class="w-full"
              phx-click="change_file_rec_max"
            />
          </div>
        </div>
        <div class="flex justify-end space-x-2 items-center">
          <.pagination_text
            start_page={@options.offset + 1}
            end_page={min(@options.max + @options.offset, @analysis.content["total_count"])}
            total_count={total_count(@analysis, @options)}
          />
          <.button phx-click="file_rec_pagination" phx-value-change="decrement">
            <div class="flex items-center">
              <Heroicons.icon name="chevron-double-left" type="mini" class="h-4 w-4" /> Previous
            </div>
          </.button>
          <.button phx-click="file_rec_pagination" phx-value-change="increment">
            <div class="flex items-center">
              Next <Heroicons.icon name="chevron-double-right" type="mini" class="h-4 w-4" />
            </div>
          </.button>
        </div>
      </div>
      <div class="overflow-auto">
        <div class="flex flex-col">
          <div class="flex flex-row bg-gray-900 p-2 mb-1 text-xs font-semibold font-mono rounded-sm text-center items-center text-gray-300">
            <div class="w-12 font-bold">Type</div>
            <div class="flex-1 font-bold ml-4">Message</div>
            <div class="w-24 font-bold">Timestamp</div>
          </div>
          <%= for {{_, [type, message, timestamp, extras]}, _idx} <- Enum.with_index(@analysis.replay_log) do %>
            <% msg_colour = PgMsgColourMapper.call(type) %>
            <div class={"flex flex-row p-2 py-1 text-gray-300 items-center bg-#{msg_colour}-500 bg-opacity-10 rounded-sm mt-1"}>
              <div class={"w-12 text-#{msg_colour}-400 text-xs text-center"}>
                [<%= type %>]
              </div>
              <div class="flex-1 overflow-auto font-mono text-gray-100 text-xs leading-relaxed scrollbar-hide [&::-webkit-scrollbar]:hidden [-ms-overflow-style:none] [scrollbar-width:none]">
                <span class="break-all">
                  <%= case type do %>
                    <% "P" -> %>
                      <% prep_statement = extras["prepared_statement"] %>
                      <%= if prep_statement != "" || prep_statement != [] do %>
                        <div class="text-emerald-600 mb-2">
                          [Prepared Statement: <%= prep_statement %>]
                        </div>
                      <% end %>

                      <span class="text-slate-200">
                        <.sql_fmt message={message} />
                      </span>
                    <% "B" -> %>
                      <%= if extras["statement_name"] != "" do %>
                        <span class="text-red-400">
                          [Stmt: <%= extras["statement_name"] %>]
                        </span>
                      <% end %>
                      <span class="text-fuchsia-400">
                        Params (<%= extras["param_count"] %>):
                      </span>
                      <%= for value <- extras["param_vals"] do %>
                        <span class="text-yellow-400">
                          [<%= value %>]
                        </span>
                      <% end %>
                    <% _ -> %>
                      <span class="text-slate-100">
                        <.sql_fmt message={message} />
                      </span>
                  <% end %>
                </span>
              </div>
              <div class="w-24 text-gray-300 text-xs text-center">
                <.format_ts
                  timestamp={String.to_integer(timestamp)}
                  date_time_format="{h24}:{m}:{s}{ss}"
                  show_time_ago={false}
                />
              </div>
            </div>
          <% end %>
        </div>
      </div>
      <div class="flex justify-end space-x-2 items-center mt-4">
        <.pagination_text
          start_page={@options.offset + 1}
          end_page={min(@options.max + @options.offset, @analysis.content["total_count"])}
          total_count={total_count(@analysis, @options)}
        />
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
    <div class="max-h-96 my-2">
      <pre class="whitespace-pre-wrap"><%= raw(String.trim(@formatted_sql)) %></pre>
    </div>
    """
  end

  defp total_count(analysis, options) do
    case options[:filter_types] do
      [] ->
        analysis.content["total_count"]

      _ ->
        Enum.reduce(analysis.content["message_type_count"], 0, fn
          {type, count}, acc ->
            if type in options[:filter_types] do
              acc + count
            else
              acc
            end
        end)
    end
  end
end
