defmodule PgSiphonManagement.Analysis.Generator do
  alias PgSiphonManagement.Analysis.Generator

  defstruct total_count: 0, message_type_count: %{}, tables_hit: %{}

  def call(raw_file) do
    result =
      raw_file
      |> Path.expand(__DIR__)
      |> File.stream!()
      |> CSV.decode()
      |> Enum.reduce(%Generator{}, &process/2)
      |> Map.from_struct()
      |> Jason.encode!()

    export(raw_file, result)

    {:ok, result}
  end

  defp export(file_name, contents) do
    file_name
    |> String.replace(".raw.csv", ".analysis.json")
    |> Path.expand(__DIR__)
    |> File.write!(contents)
  end

  defp process({:ok, row}, state) do
    state
    |> Map.update!(:total_count, &(&1 + 1))
    |> Map.update!(:message_type_count, fn
      message_type_count ->
        IO.inspect(Enum.at(row, 0))
        message_type = Enum.at(row, 0)

        Map.update(message_type_count, message_type, 1, &(&1 + 1))
    end)
  end

  defp process({:error, _reason}, state), do: state
end
