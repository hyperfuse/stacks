defmodule Stacks.Repo.Migrations.AddImageToArticles do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      add :image, :binary
    end
  end
end
