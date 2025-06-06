defmodule Stacks.Repo.Migrations.AddEnrichmentStatusToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :enrichment_status, :string, default: "pending"
    end

    create index(:items, [:enrichment_status])
  end
end
