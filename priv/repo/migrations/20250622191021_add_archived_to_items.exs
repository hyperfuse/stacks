defmodule Stacks.Repo.Migrations.AddArchivedToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :archived, :boolean, default: false, null: false
    end

    create index(:items, [:archived])
  end
end
