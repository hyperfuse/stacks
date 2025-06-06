defmodule Stacks.Repo.Migrations.RemoveDuplicateSourceUrls do
  use Ecto.Migration

  def up do
    # Remove duplicate entries, keeping only the oldest one for each source_url
    execute """
    DELETE FROM items 
    WHERE id NOT IN (
      SELECT DISTINCT ON (source_url) id 
      FROM items 
      ORDER BY source_url, inserted_at
    )
    """
  end

  def down do
    # Cannot undo deletion of duplicate records
    :ok
  end
end
