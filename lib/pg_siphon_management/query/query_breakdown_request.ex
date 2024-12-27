defmodule PgSiphonManagement.Persistence.QueryBreakdownRequest do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field :query, :string
  end

  def changeset(request, attrs) do
    request
    |> cast(attrs, [:query])
    |> validate_required([:query])
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
