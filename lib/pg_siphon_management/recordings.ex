defmodule PgSiphonManagement.Recordings do
  @doc """
  Returns the list of recordings.

  ## Examples

      iex> list_recordings()
      [%{file: "file", creation_time: ""}, ...]

  """
  def list_recordings(options \\ %{}) do
    root_dir =
      Application.get_env(:pg_siphon_management, :export)
      |> Keyword.get(:export_dir)

    files =
      root_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".raw.csv"))
      |> Enum.filter(fn file ->
        case options[:filter] do
          nil -> true
          filter -> String.contains?(file, filter)
        end
      end)
      |> Enum.map(fn file ->
        {:ok, stat} = File.stat(Path.join(root_dir, file))

        %{
          file: file,
          creation_time: stat.ctime,
          size: stat.size
        }
      end)
      |> Enum.sort_by(& &1.creation_time, :desc)

    offset = options[:offset] || 0
    max = options[:max] || length(files)

    files
    |> Enum.drop(offset)
    |> Enum.take(max)
  end

  @doc """
  Deletes a recording file.

  ## Examples

      iex> delete_recording("file.raw.csv")
      :ok
  """
  def delete_recording(file) do
    root_dir =
      Application.get_env(:pg_siphon_management, :export)
      |> Keyword.get(:export_dir)

    File.rm(Path.join(root_dir, file))
  end

  def get_recording(file) do
    root_dir =
      Application.get_env(:pg_siphon_management, :export)
      |> Keyword.get(:export_dir)

    {:ok, stat} = File.stat(Path.join(root_dir, file))

    %{
      file: file,
      creation_time: stat.ctime,
      size: stat.size
    }
  end

  def has_analysis?(file) do
    root_dir =
      Application.get_env(:pg_siphon_management, :export)
      |> Keyword.get(:export_dir)

    file = String.replace(file, ".raw.csv", ".analysis.json")

    File.exists?(Path.join(root_dir, file))
  end
end
