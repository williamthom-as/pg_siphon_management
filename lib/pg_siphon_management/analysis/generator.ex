defmodule PgSiphonManagement.Analysis.Generator do

  alias PgSiphonManagement.Analysis.Generator
  alias Phoenix.PubSub

  defstruct total_count: 0, message_type_count: %{}, tables_hit: %{}

  def call(full_path) do
    result =
      full_path
      |> Path.expand(__DIR__)
      |> File.stream!()
      |> CSV.decode()
      |> Enum.reduce(%Generator{}, &process/2)
      |> Map.from_struct()
      |> Jason.encode!()

    export(full_path, result)

    notify_pubsub(:complete, full_path)

    {:ok, result}
  end

  defp process({:ok, row}, state) do
    state
    |> Map.update!(:total_count, &(&1 + 1))
    |> Map.update!(:message_type_count, fn
      message_type_count ->
        message_type = Enum.at(row, 0)
        Map.update(message_type_count, message_type, 1, &(&1 + 1))
    end)
  end

  defp process({:error, _reason}, state), do: state

  defp export(full_path, contents) do
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
