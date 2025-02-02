defmodule PgSiphonManagement.Analysis.Generator do
  alias Plug.Debugger
  alias PgSiphonManagement.Analysis.Generator
  alias PgSiphonManagement.Query.Breakdown
  alias Phoenix.PubSub

  defstruct total_count: 0,
            message_type_count: %{},
            tables: %{},
            operations: %{},
            start_time: nil,
            end_time: nil,
            duration: nil

  def call(full_path) do
    result =
      full_path
      |> Path.expand(__DIR__)
      |> File.stream!()
      |> CSV.decode()
      |> Enum.reduce(%Generator{}, &process/2)
      |> perform_summaries()
      |> Map.from_struct()
      |> Jason.encode!()
      |> export(full_path)

    notify_pubsub(:complete, full_path)

    {:ok, result}
  end

  defp process({:ok, row}, state) do
    state
    |> set_total_count()
    |> set_message_counts(row)
    |> set_time(row)
    |> set_tables_hit(row)
  end

  defp process({:error, _reason}, state), do: state

  defp set_total_count(state) do
    state
    |> Map.update!(:total_count, &(&1 + 1))
  end

  defp set_message_counts(state, row) do
    state
    |> Map.update!(:message_type_count, fn message_type_count ->
      message_type = Enum.at(row, 0)
      Map.update(message_type_count, message_type, 1, &(&1 + 1))
    end)
  end

  defp set_tables_hit(state, row) do

    query_result = Breakdown.call(Enum.at(row, 1))
    IO.inspect query_result

    case query_result do
      {:ok, result} ->
        result
        |> Enum.reduce(state, fn {operation, _from_clause}, acc ->
          Map.update!(acc, :operations, fn ops ->
            Map.update(ops, operation, 1, &(&1 + 1))
          end)
        end)
      {:error, _} ->
        state
    end
  end

  defp set_time(%Generator{start_time: nil} = state, row) do
    time =
      Enum.at(row, 2)
      |> String.to_integer()

    # |> DateTime.from_unix!(:millisecond)

    %Generator{state | start_time: time, end_time: time}
  end

  defp set_time(state, row) do
    time =
      Enum.at(row, 2)
      |> String.to_integer()

    # |> DateTime.from_unix!(:millisecond)

    %Generator{state | end_time: time}
  end

  defp perform_summaries(%Generator{start_time: nil, end_time: _} = state) do
    %Generator{state | duration: 0}
  end

  defp perform_summaries(%Generator{start_time: start_time, end_time: end_time} = state) do
    duration_s = (end_time - start_time) / 1000

    %Generator{state | duration: duration_s}
  end

  defp export(contents, full_path) do
    full_path
    |> String.replace(".raw.csv", ".analysis.json")
    |> Path.expand(__DIR__)
    |> File.write!(contents)
  end

  def notify_pubsub(status, full_path) do
    PubSub.broadcast(
      PgSiphonManagement.PubSub,
      "analysis",
      {status, %{full_path: full_path}}
    )
  end
end
