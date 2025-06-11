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
           item_type: "unknown"  # Let the enricher determine the type
         }) do
      {:ok, item} ->
        Mix.shell().info("Line #{line_number}: Created item for #{url} (ID: #{item.id})")
        queue_enrichment_job(item)

      {:existing, item} ->
        Mix.shell().info("Line #{line_number}: Item already exists for #{url} (ID: #{item.id})")

      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
        Mix.shell().error("Line #{line_number}: Failed to create item for #{url}: #{inspect(errors)}")
    end
  end

  defp queue_enrichment_job(item) do
    %{item_id: item.id}
    |> StacksJobs.Workers.Enricher.new()
    |> Oban.insert()
  end
end