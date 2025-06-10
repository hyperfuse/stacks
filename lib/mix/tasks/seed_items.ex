defmodule Mix.Tasks.SeedItems do
  @moduledoc """
  Mix task to seed items from a text file containing URLs.

  ## Usage

      mix seed_items path/to/file.txt

  The text file should contain one URL per line. Empty lines and lines starting with # are ignored.

  ## Examples

      mix seed_items urls.txt
      mix seed_items priv/seed_data/articles.txt

  """
  use Mix.Task

  alias Stacks.Items
  alias Stacks.Articles

  @shortdoc "Seeds items from a text file containing URLs"

  def run(args) do
    Mix.Task.run("app.start")

    case args do
      [file_path] ->
        seed_from_file(file_path)

      _ ->
        Mix.shell().error("Usage: mix seed_items <file_path>")
        Mix.shell().info("Example: mix seed_items urls.txt")
    end
  end

  defp seed_from_file(file_path) do
    if File.exists?(file_path) do
      Mix.shell().info("Reading URLs from: #{file_path}")

      file_path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
      |> Enum.with_index(1)
      |> Enum.each(&process_url/1)

      Mix.shell().info("Finished seeding items")
    else
      Mix.shell().error("File not found: #{file_path}")
    end
  end

  defp process_url({url, line_number}) do
    case URI.parse(url) do
      %URI{scheme: scheme} when scheme in ["http", "https"] ->
        create_item_from_url(url, line_number)

      _ ->
        Mix.shell().error("Line #{line_number}: Invalid URL format: #{url}")
    end
  end

  defp create_item_from_url(url, line_number) do
    case Items.create_or_get_item(%{
           source_url: url,
           item_type: "article"
         }) do
      {:ok, item} ->
        Mix.shell().info("Line #{line_number}: Created item for #{url} (ID: #{item.id})")
        create_article_and_queue_job(item, url, line_number)

      {:existing, item} ->
        Mix.shell().info("Line #{line_number}: Item already exists for #{url} (ID: #{item.id})")

      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
        Mix.shell().error("Line #{line_number}: Failed to create item for #{url}: #{inspect(errors)}")
    end
  end

  defp create_article_and_queue_job(item, url, line_number) do
    case Articles.create_article(%{
           source_url: url,
           item_id: item.id
         }) do
      {:ok, article} ->
        Mix.shell().info("Line #{line_number}: Created article for #{url} (ID: #{article.id})")
        queue_enrichment_job(article)

      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
        Mix.shell().error("Line #{line_number}: Failed to create article for #{url}: #{inspect(errors)}")
    end
  end

  defp queue_enrichment_job(article) do
    %{article_id: article.id}
    |> StacksJobs.Workers.WebpageEnricher.new()
    |> Oban.insert()
  end
end