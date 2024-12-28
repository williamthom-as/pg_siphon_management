defmodule PgSiphonManagementWeb.QueryBreakdownLive do
  use PgSiphonManagementWeb, :live_view

  alias PgSiphonManagement.Persistence.QueryBreakdownRequest

  def mount(_params, _session, socket) do
    {_, changeset} = QueryBreakdownRequest.create(%{})

    {:ok,
      socket
      |> assign(form: to_form(changeset))
      |> assign(query: nil)
      |> assign(breakdown: nil)
    }
  end

  def render(assigns) do
    ~H"""
      <.two_columns>
        <:left_section>
          <.query_form form={@form}></.query_form>
        </:left_section>
        <:right_section>
          <div class="text-gray-600">
            <%= @query %>

            <%= if @breakdown do %>
              <div class="mt-4">
                <h2 class="text-lg font-semibold">Breakdown</h2>
                <%= for stmt <- @breakdown.stmts do %>
                  <div class="mt-4">
                    <h3 class="text-base font-semibold">Statement</h3>
                    <pre><%= inspect stmt %></pre>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </:right_section>
      </.two_columns>
    """
  end

  def query_form(assigns) do
    ~H"""
    <div class="wrapper">
      <div class="flex items-center gap-4">
        <div class="flex-1">
          <.form for={@form} id="query-breakdown-form" phx-submit="submit">
            <.input
              type="textarea"
              field={@form[:query]}
              label="Query"
              placeholder="Enter your SQL query to provide breakdown"
              autocomplete="off"
              phx-debounce={400}
            />
            <.button
              phx-disable-with="Submitting ..."
              class="border border-blue-500 text-blue-500 hover:bg-blue-500 hover:text-white font-semibold py-1 px-2 rounded w-full text-xs mt-2"
            >
              Perform
            </.button>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("submit", %{"query_breakdown_request" => %{"query" => query} = f_params}, socket) do
    case QueryBreakdownRequest.create(f_params) do
      {:ok, _new_request} ->
        new_changeset = QueryBreakdownRequest.changeset(%QueryBreakdownRequest{}, %{"query" => query})

        breakdown = with {:ok, breakdown} <- PgQuery.parse(query), do: breakdown

        {:noreply,
          socket
          |> assign(:form, to_form(new_changeset))
          |> assign(:query, query)
          |> assign(:breakdown, breakdown)
        }
      {:error, changeset} ->
        changeset =
          changeset
          |> Map.put(:action, :validate)

        {:noreply, socket |> assign(:form, to_form(changeset))}
    end
  end
end
