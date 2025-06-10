defmodule Stacks.Items do
  @moduledoc """
  The Items context.
  """

  import Ecto.Query, warn: false
  alias Stacks.Repo

  alias Stacks.Items.Item

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items()
      [%Item{}, ...]

  """
  def list_items do
    Item
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns the list of items with their associated articles preloaded.

  ## Examples

      iex> list_items_with_articles()
      [%Item{article: %Article{} | nil}, ...]

  """
  def list_items_with_articles do
    Item
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload(:article)
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(123)
      %Item{}

      iex> get_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(id), do: Repo.get!(Item, id)

  @doc """
  Gets a single item with its associated article preloaded.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item_with_article!(123)
      %Item{article: %Article{}}

      iex> get_item_with_article!(456)
      ** (Ecto.NoResultsError)

  """
  def get_item_with_article!(id) do
    Item
    |> Repo.get!(id)
    |> Repo.preload(:article)
  end

  @doc """
  Gets a single item by source_url.

  Returns `nil` if no item exists with the given source_url.

  ## Examples

      iex> get_item_by_source_url("https://example.com")
      %Item{}

      iex> get_item_by_source_url("https://nonexistent.com")
      nil

  """
  def get_item_by_source_url(source_url) do
    Repo.get_by(Item, source_url: source_url)
  end

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(%{field: value})
      {:ok, %Item{}}

      iex> create_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(attrs \\ %{}) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a item or returns the existing one if source_url already exists.

  ## Examples

      iex> create_or_get_item(%{source_url: "https://example.com", item_type: "article"})
      {:ok, %Item{}}

      iex> create_or_get_item(%{source_url: "https://example.com", item_type: "article"})
      {:existing, %Item{}}

  """
  def create_or_get_item(attrs \\ %{}) do
    case attrs["source_url"] || attrs[:source_url] do
      nil ->
        create_item(attrs)

      source_url ->
        case get_item_by_source_url(source_url) do
          nil ->
            create_item(attrs)

          existing_item ->
            {:existing, existing_item}
        end
    end
  end

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a item.

  ## Examples

      iex> delete_item(item)
      {:ok, %Item{}}

      iex> delete_item(item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(item)
      %Ecto.Changeset{data: %Item{}}

  """
  def change_item(%Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end
end
