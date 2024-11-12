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

    offset = options[:offset] || 0
    max = options[:max] || 10

    root_dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".raw.csv"))
    |> Enum.filter(fn file_name ->
      case options[:filter] do
        nil -> true
        filter -> String.contains?(file_name, filter)
      end
    end)
    |> Enum.map(fn file_name ->
      full_path = Path.join(root_dir, file_name)
      {:ok, stat} = File.stat(full_path)

      %{
        file_name: file_name,
        full_path: full_path,
        creation_time: stat.ctime,
        has_analysis: has_analysis?(file_name),
        size: stat.size
      }
    end)
    |> Enum.drop(offset)
    |> Enum.take(max)
    |> Enum.sort_by(& &1.creation_time, :desc)
  end

  def get_recording(file_name) do
    full_path = expand_file_name(file_name)

    case File.stat(full_path) do
      {:ok, stat} ->
        %{
          file_name: file_name,
          full_path: full_path,
          creation_time: stat.ctime,
          has_analysis: has_analysis?(file_name),
          size: stat.size
        }

      {:error, _reason} ->
        nil
    end
  end

  @doc """
  Deletes a recording file.

  ## Examples

      iex> delete_recording("file.raw.csv")
      :ok
  """
  def delete_recording(file_name) do
    file_name
    |> expand_file_name()
    |> File.rm()

    file_name
    |> get_analysis_file_path()
    |> IO.inspect()
    |> File.rm()

    :ok
  end

  def has_analysis?(raw_file_name) do
    get_analysis_file_path(raw_file_name)
    |> File.exists?()
  end

  def get_analysis(raw_file_name) do
    file_path = get_analysis_file_path(raw_file_name)

    case File.exists?(file_path) do
      true ->
        {:ok, stats} = File.stat(file_path)

        content =
          file_path
          |> File.read!()
          |> Jason.decode!()

        {:ok,
         %{
           file_name: raw_file_name,
           full_path: file_path,
           creation_time: stats.ctime,
           size: stats.size,
           content: content
         }}

      false ->
        {:enoent, nil}
    end
  end

  defp expand_file_name(file_name) do
    root_dir =
      Application.get_env(:pg_siphon_management, :export)
      |> Keyword.get(:export_dir)

    Path.join(root_dir, file_name)
  end

  defp get_analysis_file_path(file_name) do
    expand_file_name(file_name)
    |> String.replace(".raw.csv", ".analysis.json")
  end
end
