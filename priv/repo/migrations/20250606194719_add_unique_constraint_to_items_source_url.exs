defmodule Stacks.Repo.Migrations.AddUniqueConstraintToItemsSourceUrl do
  use Ecto.Migration

  def change do
    create unique_index(:items, [:source_url])
  end
end
