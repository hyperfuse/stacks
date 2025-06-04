defmodule StacksJobs.Workers.WebpageEnricher do
  use Oban.Worker, queue: :default, max_attempts: 3
  alias Stacks.Items
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    IO.puts("Processing job with ID #{id}")

    # TODO Check the error
    item = Items.get_item!(id)
    summary = Readability.summarize(item.source_url)

    # TODO check errors
    Items.update_item(item, %{
      "metadata" => %{
        "article_text" => summary.article_text,
        "article_html" => summary.article_html,
        "title" => summary.title,
        "authors" => summary.authors
      }
    })
  end

  def insert(%{"id" => id}) do
    StacksJobs.Workers.WebpageEnricher.new(%{"id" => id})
    |> Oban.insert()
  end
end
