defmodule Stacks.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "users" do


    timestamps(type: :utc_datetime)
  end

  @doc false
  def generate_id, do: Nanoid.generate()

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> validate_required([])
    |> put_id()
  end

  defp put_id(%Ecto.Changeset{data: %{id: nil}} = changeset) do
    put_change(changeset, :id, generate_id())
  end
  defp put_id(changeset), do: changeset
end
