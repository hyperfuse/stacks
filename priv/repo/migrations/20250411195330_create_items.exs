defmodule Stacks.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :item_type, :string
      add :source_url, :string
      add :title, :string
      add :text_content, :string
      add :metadata, :map
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:items, [:user_id])
  end
end
