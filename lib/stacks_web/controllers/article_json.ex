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
      html_content: article.html_content,
      text_content: article.text_content,
      metadata: article.metadata,
      image: encode_image(article.image),
      item_id: article.item_id,
      user_id: article.user_id
    }
  end

  defp encode_image(nil), do: nil

  defp encode_image(image_binary) when is_binary(image_binary) do
    Base.encode64(image_binary)
  end
end
