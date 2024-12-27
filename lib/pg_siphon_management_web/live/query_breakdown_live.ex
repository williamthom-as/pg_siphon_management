defmodule PgSiphonManagementWeb.QueryBreakdownLive do
  use PgSiphonManagementWeb, :live_view

  alias PgSiphonManagement.Persistence.QueryBreakdownRequest

  def mount(_params, _session, socket) do
    {_, query_changeset} = QueryBreakdownRequest.create(%{})

    {:ok, assign(socket, form: to_form(query_changeset))}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.two_columns>
        <:left_section>
          <h5 class="mb-4 text-base font-mono text-md text-gray-200">
            Query Breakdown
          </h5>
          <.query_form form={@form}></.query_form>
        </:left_section>
        <:right_section>
          <div class="text-gray-600">
            Here!
          </div>
        </:right_section>
      </.two_columns>
    </div>
    """
  end

  def query_form(assigns) do
    ~H"""
    <div class="">
      <div class="flex items-center gap-4">
        <div class="flex-1">
          <.form for={@form} id="query-breakdown-form" phx-submit="search">
            <.input
              type="textarea"
              field={@form[:query]}
              value=""
              placeholder="Enter query to provide breakdown"
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

  def handle_event("search", %{"query_breakdown_request" => %{"query" => _query}} = f_params, socket) do
    case QueryBreakdownRequest.create(f_params) do
      {:ok, _new_request} ->
        # Do the thing!


        {:noreply, socket}

      {:error, changeset} ->
        IO.puts "in error"

        changeset =
          changeset
          |> Map.put(:action, :validate)

        {:noreply, socket |> assign(:form, to_form(changeset))}
    end
  end

end
