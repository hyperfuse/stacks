defmodule Stacks.Items.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :item_type, :string
    field :metadata, :map
    field :source_url, :string
    field :text_content, :string
    field :enrichment_status, Ecto.Enum, values: [:pending, :processing, :completed, :failed], default: :pending
    field :user_id, :id
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:item_type, :source_url, :text_content, :metadata, :enrichment_status])
    |> validate_required([:item_type, :source_url])
    |> validate_inclusion(:enrichment_status, [:pending, :processing, :completed, :failed])
  end
end
