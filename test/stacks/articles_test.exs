defmodule Stacks.ArticlesTest do
  use Stacks.DataCase

  alias Stacks.Articles

  describe "articles" do
    alias Stacks.Articles.Article

    import Stacks.ArticlesFixtures

    @invalid_attrs %{title: nil, source_url: nil, content: nil, metadata: nil}

    test "list_articles/0 returns all articles" do
      article = article_fixture()
      assert Articles.list_articles() == [article]
    end

    test "get_article!/1 returns the article with given id" do
      article = article_fixture()
      assert Articles.get_article!(article.id) == article
    end

    test "create_article/1 with valid data creates a article" do
      item = Stacks.ItemsFixtures.item_fixture(%{item_type: "article", source_url: "https://test.com", enrichment_status: :pending})
      valid_attrs = %{title: "some title", source_url: "https://test.com", content: "some content", metadata: %{}, item_id: item.id}

      assert {:ok, %Article{} = article} = Articles.create_article(valid_attrs)
      assert article.title == "some title"
      assert article.source_url == "https://test.com"
      assert article.content == "some content"
      assert article.metadata == %{}
    end

    test "create_article/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Articles.create_article(@invalid_attrs)
    end

    test "update_article/2 with valid data updates the article" do
      article = article_fixture()
      update_attrs = %{title: "some updated title", source_url: "https://updated.com", content: "some updated content", metadata: %{updated: true}}

      assert {:ok, %Article{} = article} = Articles.update_article(article, update_attrs)
      assert article.title == "some updated title"
      assert article.source_url == "https://updated.com"
      assert article.content == "some updated content"
      assert article.metadata == %{updated: true}
    end

    test "update_article/2 with invalid data returns error changeset" do
      article = article_fixture()
      assert {:error, %Ecto.Changeset{}} = Articles.update_article(article, @invalid_attrs)
      assert article == Articles.get_article!(article.id)
    end

    test "delete_article/1 deletes the article" do
      article = article_fixture()
      assert {:ok, %Article{}} = Articles.delete_article(article)
      assert_raise Ecto.NoResultsError, fn -> Articles.get_article!(article.id) end
    end

    test "change_article/1 returns a article changeset" do
      article = article_fixture()
      assert %Ecto.Changeset{} = Articles.change_article(article)
    end
  end
end