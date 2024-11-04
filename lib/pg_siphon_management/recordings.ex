defmodule PgSiphonManagement.Recordings do
  @doc """
  Returns the list of recordings.

  ## Examples

      iex> list_recordings()
      [%{file: "file", creation_time: ""}, ...]

  """

  def list_recordings do
    root_dir =
      Application.get_env(:pg_siphon_management, :export)
      |> Keyword.get(:export_dir)

    root_dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".raw.csv"))
    |> Enum.map(fn file ->
      {:ok, stat} = File.stat(Path.join(root_dir, file))

      %{
        file: file,
        creation_time: stat.ctime
      }
    end)
  end
end
