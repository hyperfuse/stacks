defmodule Stacks.Articles.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "articles" do
    field :title, :string
    field :source_url, :string
    field :content, :string
    field :metadata, :map
    field :status, :string, default: "pending"
    belongs_to :item, Stacks.Items.Item
    belongs_to :user, Stacks.Accounts.User
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:title, :source_url, :content, :metadata, :status, :item_id, :user_id])
    |> validate_required([:source_url, :item_id])
    |> validate_inclusion(:status, ["pending", "processing", "completed", "failed"])
  end
end