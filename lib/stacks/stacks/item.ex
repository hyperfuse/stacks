defmodule Stacks.Stacks.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :item_type, :string
    field :metadata, :map
    field :source_url, :string
    field :text_content, :string
    field :title, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:item_type, :source_url, :title, :text_content, :metadata])
    |> validate_required([:item_type, :source_url, :title, :text_content])
  end
end
