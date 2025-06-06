defmodule StacksWeb.ArticleJSON do
  alias Stacks.Articles.Article

  @doc """
  Renders a list of articles.
  """
  def index(%{articles: articles}) do
    %{data: for(article <- articles, do: data(article))}
  end

  @doc """
  Renders a single article.
  """
  def show(%{article: article}) do
    %{data: data(article)}
  end

  defp data(%Article{} = article) do
    %{
      id: article.id,
      title: article.title,
      source_url: article.source_url,
      content: article.content,
      metadata: article.metadata,
      item_id: article.item_id,
      user_id: article.user_id
    }
  end
end