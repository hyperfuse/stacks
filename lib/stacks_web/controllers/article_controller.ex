defmodule StacksWeb.ArticleController do
  use StacksWeb, :controller

  alias Stacks.Articles
  alias Stacks.Articles.Article
  alias Stacks.Items
  alias StacksJobs.Workers.WebpageEnricher

  action_fallback StacksWeb.FallbackController

  def index(conn, _params) do
    articles = Articles.list_articles()
    render(conn, :index, articles: articles)
  end

  def create(conn, %{"article" => article_params}) do
    # First create an item
    item_params = %{
      "item_type" => "article",
      "source_url" => article_params["source_url"]
    }
    
    case Items.create_item(item_params) do
      {:ok, item} ->
        # Then create the article linked to the item
        article_params_with_item = Map.put(article_params, "item_id", item.id)
        
        case Articles.create_article(article_params_with_item) do
          {:ok, article} ->
            # Enqueue the enrichment job
            WebpageEnricher.insert(%{"article_id" => article.id})
            
            conn
            |> put_status(:created)
            |> put_resp_header("location", ~p"/api/articles/#{article}")
            |> render(:show, article: article)
          
          {:error, changeset} ->
            # Clean up the item if article creation fails
            Items.delete_item(item)
            {:error, changeset}
        end
      
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def show(conn, %{"id" => id}) do
    article = Articles.get_article!(id)
    render(conn, :show, article: article)
  end

  def update(conn, %{"id" => id, "article" => article_params}) do
    article = Articles.get_article!(id)

    with {:ok, %Article{} = article} <- Articles.update_article(article, article_params) do
      render(conn, :show, article: article)
    end
  end

  def delete(conn, %{"id" => id}) do
    article = Articles.get_article!(id)

    with {:ok, %Article{}} <- Articles.delete_article(article) do
      send_resp(conn, :no_content, "")
    end
  end
end