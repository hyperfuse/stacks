defmodule Stacks.Videos.Video do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "videos" do
    field :title, :string
    field :source_url, :string
    field :duration, :integer
    field :thumbnail_url, :string
    field :thumbnail, :binary
    field :description, :string
    field :video_id, :string
    field :platform, :string
    field :metadata, :map
    belongs_to :item, Stacks.Items.Item, type: :string
    belongs_to :user, Stacks.Accounts.User, type: :string
    timestamps(type: :utc_datetime)
  end

  @doc false
  def generate_id, do: Nanoid.generate()

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [
      :title,
      :source_url,
      :duration,
      :thumbnail_url,
      :thumbnail,
      :description,
      :video_id,
      :platform,
      :metadata,
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