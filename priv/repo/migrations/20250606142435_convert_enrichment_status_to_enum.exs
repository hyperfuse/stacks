defmodule Stacks.Repo.Migrations.ConvertEnrichmentStatusToEnum do
  use Ecto.Migration

  def up do
    # Create the enum type
    execute "CREATE TYPE enrichment_status_type AS ENUM ('pending', 'processing', 'completed', 'failed')"
    
    # Add a new column with the enum type
    alter table(:items) do
      add :enrichment_status_enum, :enrichment_status_type, default: "pending"
    end
    
    # Copy data from string column to enum column
    execute "UPDATE items SET enrichment_status_enum = enrichment_status::enrichment_status_type"
    
    # Drop the old string column and index
    drop index(:items, [:enrichment_status])
    
    alter table(:items) do
      remove :enrichment_status, :string
    end
    
    # Rename the enum column to the original name
    rename table(:items), :enrichment_status_enum, to: :enrichment_status
    
    # Re-create the index
    create index(:items, [:enrichment_status])
  end

  def down do
    # Drop the index
    drop index(:items, [:enrichment_status])
    
    # Rename back to temp name
    rename table(:items), :enrichment_status, to: :enrichment_status_enum
    
    # Add back the string column
    alter table(:items) do
      add :enrichment_status, :string, default: "pending"
    end
    
    # Copy data back to string column
    execute "UPDATE items SET enrichment_status = enrichment_status_enum::text"
    
    # Remove the enum column
    alter table(:items) do
      remove :enrichment_status_enum, :enrichment_status_type
    end
    
    # Drop the enum type
    execute "DROP TYPE enrichment_status_type"
    
    # Re-create the index
    create index(:items, [:enrichment_status])
  end
end
