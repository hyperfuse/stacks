defmodule StacksJobs.Workers.WebpageEnricher do
  use Oban.Worker, queue: :default, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    # Your job logic here
    IO.puts("Processing job with ID #{id}")
    :ok
  end

  def insert(%{"id" => id}) do
    StacksJobs.Workers.WebpageEnricher.new(%{"id" => id})
    |> Oban.insert()
  end
end
