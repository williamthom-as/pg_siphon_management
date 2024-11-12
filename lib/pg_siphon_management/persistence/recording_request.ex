defmodule PgSiphonManagement.Persistence.RecordingRequest do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field :file_name, :string
    field :file_format, :string
  end

  def changeset(request, attrs) do
    request
    |> cast(attrs, [:file_name, :file_format])
    |> validate_required([:file_name, :file_format])
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_changeset()
  end

  def apply_changeset(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true} ->
        {:ok, apply_changes(changeset)}

      _ ->
        {:error, changeset}
    end
  end
end
