defmodule Stacks.Items.Item do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "items" do
    field :item_type, :string
    field :metadata, :map
    field :source_url, :string
    field :source_website, :string
    field :favicon_url, :string
    field :text_content, :string
    field :enrichment_status, Ecto.Enum, values: [:pending, :processing, :completed, :failed], default: :pending
    field :user_id, :string
    has_one :article, Stacks.Articles.Article
    timestamps(type: :utc_datetime)
  end

  @doc false
  def generate_id, do: Nanoid.generate()

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:item_type, :source_url, :source_website, :favicon_url, :text_content, :metadata, :enrichment_status])
    |> validate_required([:item_type, :source_url])
    |> validate_inclusion(:enrichment_status, [:pending, :processing, :completed, :failed])
    |> unique_constraint(:source_url)
    |> put_id()
  end

  defp put_id(%Ecto.Changeset{data: %{id: nil}} = changeset) do
    put_change(changeset, :id, generate_id())
  end
  defp put_id(changeset), do: changeset
end
