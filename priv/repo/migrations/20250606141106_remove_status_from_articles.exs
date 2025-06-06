defmodule Stacks.Repo.Migrations.RemoveStatusFromArticles do
  use Ecto.Migration

  def change do
    drop index(:articles, [:status])
    
    alter table(:articles) do
      remove :status, :string
    end
  end
end
