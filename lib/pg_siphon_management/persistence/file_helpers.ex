defmodule PgSiphonManagement.Persistence.FileHelpers do
  def make_dir_p(root_path, folder) do
    Path.join(root_path, folder)
    |> make_dir_p()
  end

  def make_dir_p(root_path) do
    case File.exists?(root_path) do
      true ->
        {:ok, "path exists"}

      false ->
        File.mkdir_p!(root_path)
        {:ok, "path created"}
    end
  end
end
