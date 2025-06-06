defmodule StacksJobs.Workers.WebpageEnricher do
  use Oban.Worker, queue: :default, max_attempts: 3
  alias Stacks.Articles
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"article_id" => article_id}}) do
    IO.puts("Processing article enrichment job for article ID #{article_id}")

    # Get the article
    article = Articles.get_article!(article_id)
    
    # Update status to processing
    Articles.update_article(article, %{"status" => "processing"})

    try do
      # Extract content using Readability
      summary = Readability.summarize(article.source_url)

      # Update article with enriched content
      Articles.update_article(article, %{
        "title" => summary.title,
        "content" => summary.article_text,
        "metadata" => %{
          "article_html" => summary.article_html,
          "authors" => summary.authors,
          "extracted_at" => DateTime.utc_now()
        },
        "status" => "completed"
      })
    rescue
      error ->
        IO.puts("Error enriching article #{article_id}: #{inspect(error)}")
        Articles.update_article(article, %{"status" => "failed"})
        {:error, error}
    end
  end

  # Support legacy format for backward compatibility
  def perform(%Oban.Job{args: %{"id" => id}}) do
    perform(%Oban.Job{args: %{"article_id" => id}})
  end

  def insert(%{"article_id" => article_id}) do
    StacksJobs.Workers.WebpageEnricher.new(%{"article_id" => article_id})
    |> Oban.insert()
  end

  # Support legacy format for backward compatibility
  def insert(%{"id" => id}) do
    insert(%{"article_id" => id})
  end
end
