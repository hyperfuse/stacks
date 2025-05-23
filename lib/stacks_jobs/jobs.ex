defmodule StacksJobs.Workers.WebpageEnricher do
  use Oban.Worker, queue: :default, max_attempts: 3
  alias Stacks.Items
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    IO.puts("Processing job with ID #{id}")

    # Check the error
    item = Items.get_item!(id)
    summary = Readability.summarize(item.source_url)
    IO.inspect(summary)
    # Clean the url
    :ok
  end

  def insert(%{"id" => id}) do
    StacksJobs.Workers.WebpageEnricher.new(%{"id" => id})
    |> Oban.insert()
  end
end
