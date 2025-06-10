defmodule Stacks.Repo.Migrations.AddHtmlContentAndTextContentToArticles do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      add :html_content, :text
      add :text_content, :text
    end
  end
end
