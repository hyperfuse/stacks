defmodule Stacks.Repo.Migrations.ConvertUuidToNanoid do
  use Ecto.Migration

  def up do
    # First, create a function to generate nanoid
    execute """
    CREATE OR REPLACE FUNCTION generate_nanoid(size int DEFAULT 21)
    RETURNS text AS $$
    DECLARE
      alphabet text := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_';
      result text := '';
      i int := 0;
    BEGIN
      LOOP
        EXIT WHEN i = size;
        result := result || substr(alphabet, (random() * 63)::int + 1, 1);
        i := i + 1;
      END LOOP;
      RETURN result;
    END;
    $$ LANGUAGE plpgsql;
    """

    # Convert users table
    execute "ALTER TABLE users ADD COLUMN new_id text DEFAULT generate_nanoid()"
    execute "UPDATE users SET new_id = generate_nanoid() WHERE new_id IS NULL"
    execute "ALTER TABLE users ALTER COLUMN new_id SET NOT NULL"

    # Update references in items table
    execute "ALTER TABLE items ADD COLUMN new_user_id text"

    execute "UPDATE items SET new_user_id = users.new_id FROM users WHERE items.user_id = users.id"

    execute "ALTER TABLE items DROP CONSTRAINT items_user_id_fkey"
    execute "ALTER TABLE items DROP COLUMN user_id"
    execute "ALTER TABLE items RENAME COLUMN new_user_id TO user_id"

    # Update references in articles table  
    execute "ALTER TABLE articles ADD COLUMN new_user_id text"

    execute "UPDATE articles SET new_user_id = users.new_id FROM users WHERE articles.user_id = users.id"

    execute "ALTER TABLE articles DROP CONSTRAINT articles_user_id_fkey"
    execute "ALTER TABLE articles DROP COLUMN user_id"
    execute "ALTER TABLE articles RENAME COLUMN new_user_id TO user_id"

    # Complete users table conversion
    execute "ALTER TABLE users DROP CONSTRAINT users_pkey"
    execute "ALTER TABLE users DROP COLUMN id"
    execute "ALTER TABLE users RENAME COLUMN new_id TO id"
    execute "ALTER TABLE users ADD PRIMARY KEY (id)"

    # Convert items table
    execute "ALTER TABLE items ADD COLUMN new_id text DEFAULT generate_nanoid()"
    execute "UPDATE items SET new_id = generate_nanoid() WHERE new_id IS NULL"
    execute "ALTER TABLE items ALTER COLUMN new_id SET NOT NULL"

    # Update references in articles table
    execute "ALTER TABLE articles ADD COLUMN new_item_id text"

    execute "UPDATE articles SET new_item_id = items.new_id FROM items WHERE articles.item_id = items.id"

    execute "ALTER TABLE articles DROP CONSTRAINT articles_item_id_fkey"
    execute "ALTER TABLE articles DROP COLUMN item_id"
    execute "ALTER TABLE articles RENAME COLUMN new_item_id TO item_id"

    # Complete items table conversion
    execute "ALTER TABLE items DROP CONSTRAINT items_pkey"
    execute "ALTER TABLE items DROP COLUMN id"
    execute "ALTER TABLE items RENAME COLUMN new_id TO id"
    execute "ALTER TABLE items ADD PRIMARY KEY (id)"

    # Convert articles table
    execute "ALTER TABLE articles ADD COLUMN new_id text DEFAULT generate_nanoid()"
    execute "UPDATE articles SET new_id = generate_nanoid() WHERE new_id IS NULL"
    execute "ALTER TABLE articles ALTER COLUMN new_id SET NOT NULL"
    execute "ALTER TABLE articles DROP CONSTRAINT articles_pkey"
    execute "ALTER TABLE articles DROP COLUMN id"
    execute "ALTER TABLE articles RENAME COLUMN new_id TO id"
    execute "ALTER TABLE articles ADD PRIMARY KEY (id)"

    # Recreate foreign key constraints
    alter table(:items) do
      modify :user_id, references(:users, type: :string, on_delete: :nothing)
    end

    alter table(:articles) do
      modify :item_id, references(:items, type: :string, on_delete: :nothing), null: false
      modify :user_id, references(:users, type: :string, on_delete: :nothing)
    end

    # Recreate indexes
    create index(:items, [:user_id])
    create index(:articles, [:item_id])
    create index(:articles, [:user_id])
  end

  def down do
    # This is a destructive migration - rolling back would lose data
    # In a real-world scenario, you might want to implement a proper rollback
    raise "Cannot rollback nanoid conversion - this would lose data"
  end
end
