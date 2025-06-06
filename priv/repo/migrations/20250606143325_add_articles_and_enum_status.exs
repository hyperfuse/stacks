defmodule Stacks.Repo.Migrations.AddArticlesAndEnumStatus do
  use Ecto.Migration

  def up do
    # Create the enum type for enrichment status
    execute "CREATE TYPE enrichment_status_type AS ENUM ('pending', 'processing', 'completed', 'failed')"
    
    # Add enrichment_status field to items table using the enum
    alter table(:items) do
      add :enrichment_status, :enrichment_status_type, default: "pending"
    end

    create index(:items, [:enrichment_status])

    # Create articles table without status field (status is now on items)
    create table(:articles) do
      add :title, :string
      add :source_url, :string, null: false
      add :content, :text
      add :metadata, :map
      add :item_id, references(:items, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:articles, [:item_id])
    create index(:articles, [:user_id])
  end

  def down do
    # Drop articles table and indexes
    drop index(:articles, [:user_id])
    drop index(:articles, [:item_id])
    drop table(:articles)

    # Drop enrichment_status from items
    drop index(:items, [:enrichment_status])
    
    alter table(:items) do
      remove :enrichment_status, :enrichment_status_type
    end

    # Drop the enum type
    execute "DROP TYPE enrichment_status_type"
  end
end
