defmodule Stacks.Stacks.Item do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "items" do
    field :item_type, :string
    field :metadata, :map
    field :source_url, :string
    field :text_content, :string
    field :title, :string
    field :user_id, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def generate_id, do: Nanoid.generate()

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:item_type, :source_url, :title, :text_content, :metadata])
    |> validate_required([:item_type, :source_url, :title, :text_content])
    |> put_id()
  end

  defp put_id(%Ecto.Changeset{data: %{id: nil}} = changeset) do
    put_change(changeset, :id, generate_id())
  end
  defp put_id(changeset), do: changeset
end
