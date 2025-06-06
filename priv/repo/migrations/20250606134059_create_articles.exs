defmodule Stacks.Repo.Migrations.CreateArticles do
  use Ecto.Migration

  def change do
    create table(:articles) do
      add :title, :string
      add :source_url, :string, null: false
      add :content, :text
      add :metadata, :map
      add :status, :string, default: "pending"
      add :item_id, references(:items, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:articles, [:item_id])
    create index(:articles, [:user_id])
    create index(:articles, [:status])
  end
end
