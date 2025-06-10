defmodule Stacks.Repo.Migrations.AddSourceWebsiteAndFaviconToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :source_website, :string
      add :favicon_url, :string
    end
  end
end
