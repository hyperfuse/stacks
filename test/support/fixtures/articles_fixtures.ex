defmodule Stacks.ArticlesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Stacks.Articles` context.
  """

  @doc """
  Generate an article.
  """
  def article_fixture(attrs \\ %{}) do
    # Create an item first since article requires it
    item = Stacks.ItemsFixtures.item_fixture(%{
      item_type: "article",
      source_url: "https://example.com/article",
      enrichment_status: "pending"
    })

    {:ok, article} =
      attrs
      |> Enum.into(%{
        title: "some title",
        source_url: "https://example.com/article",
        content: "some content",
        metadata: %{},
        item_id: item.id
      })
      |> Stacks.Articles.create_article()

    article
  end
end