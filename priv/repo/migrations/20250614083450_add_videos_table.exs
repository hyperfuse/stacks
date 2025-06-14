defmodule Stacks.Repo.Migrations.AddVideosTable do
  use Ecto.Migration

  def change do
    create table(:videos, primary_key: false) do
      add :id, :string, primary_key: true
      add :title, :string
      add :source_url, :string, null: false
      add :duration, :integer
      add :thumbnail_url, :string
      add :description, :text
      add :video_id, :string
      add :platform, :string
      add :metadata, :map
      add :item_id, references(:items, type: :string, on_delete: :nothing), null: false
      add :user_id, references(:users, type: :string, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:videos, [:item_id])
    create index(:videos, [:user_id])
    create index(:videos, [:platform])
    create index(:videos, [:video_id])
  end
end
