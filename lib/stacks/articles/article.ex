defmodule Stacks.Articles.Article do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "articles" do
    field :title, :string
    field :source_url, :string
    field :content, :string
    field :html_content, :string
    field :text_content, :string
    field :metadata, :map
    field :image, :binary
    belongs_to :item, Stacks.Items.Item, type: :string
    belongs_to :user, Stacks.Accounts.User, type: :string
    timestamps(type: :utc_datetime)
  end

  @doc false
  def generate_id, do: Nanoid.generate()

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [
      :title,
      :source_url,
      :content,
      :html_content,
      :text_content,
      :metadata,
      :image,
      :item_id,
      :user_id
    ])
    |> validate_required([:source_url, :item_id])
    |> put_id()
  end

  defp put_id(%Ecto.Changeset{data: %{id: nil}} = changeset) do
    put_change(changeset, :id, generate_id())
  end

  defp put_id(changeset), do: changeset
end
