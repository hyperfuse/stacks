defmodule StacksJobs.Workers.Enricher do
  use Oban.Worker, queue: :default, max_attempts: 3
  alias Stacks.Articles
  alias Stacks.Items
  alias Stacks.Categorizer
  alias Stacks.Categorizers.ArticleCategorizer
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"item_id" => item_id}}) do
    IO.puts("Processing enrichment job for item ID #{item_id}")

    # Get the item
    item = Items.get_item!(item_id)

    # Update item enrichment status to processing
    Items.update_item(item, %{"enrichment_status" => :processing})

    try do
      # Categorize the item using configured categorizers
      categorizers = [ArticleCategorizer]

      case categorize_item(item.source_url, categorizers) do
        {:ok, {:article, metadata}} ->
          # Set item type to article
          Items.update_item(item, %{"item_type" => "article"})

          # Create article record using all metadata from categorizer
          {:ok, _article} =
            Articles.create_article(%{
              "item_id" => item.id,
              "source_url" => item.source_url,
              "title" => metadata["title"],
              "html_content" => metadata["html_content"],
              "text_content" => metadata["text_content"],
              "image" => metadata["image"],
              "metadata" => Map.take(metadata, ["authors", "detected_by", "extracted_at"])
            })

          # Update item with website info and enrichment status
          Items.update_item(item, %{
            "source_website" => metadata["source_website"],
            "favicon_url" => metadata["favicon_url"],
            "enrichment_status" => :completed
          })

        {:ok, nil} ->
          # No categorizer matched, just extract basic website info
          {source_website, favicon_url} = extract_website_info(item.source_url)

          Items.update_item(item, %{
            "source_website" => source_website,
            "favicon_url" => favicon_url,
            "enrichment_status" => :completed
          })

        _ ->
          # Fallback for any other case
          {source_website, favicon_url} = extract_website_info(item.source_url)

          Items.update_item(item, %{
            "source_website" => source_website,
            "favicon_url" => favicon_url,
            "enrichment_status" => :completed
          })
      end
    rescue
      error ->
        IO.puts("Error enriching item #{item_id}: #{inspect(error)}")
        Items.update_item(item, %{"enrichment_status" => :failed})
        {:error, error}
    end
  end


  def insert(%{"item_id" => item_id}) do
    StacksJobs.Workers.Enricher.new(%{"item_id" => item_id})
    |> Oban.insert()
  end


  # Categorize an item using the configured categorizers
  defp categorize_item(url, categorizers) do
    case Finch.build(:get, url) |> Finch.request(Stacks.Finch) do
      {:ok, %{status: 200, body: html}} ->
        Categorizer.categorize_with_multiple(categorizers, url, html)

      _ ->
        {:ok, nil}
    end
  rescue
    _ ->
      {:ok, nil}
  end

  # Extract basic website info for non-article items
  defp extract_website_info(url) do
    try do
      uri = URI.parse(url)
      domain = uri.host || "Unknown Source"
      
      # Basic domain-based website name
      website_name = domain
                     |> String.replace_prefix("www.", "")
                     |> String.split(".")
                     |> List.first()
                     |> String.capitalize()
      
      # Basic favicon URL
      favicon_url = if uri.scheme && uri.host do
        port_part = if uri.port && uri.port != 80 && uri.port != 443, do: ":#{uri.port}", else: ""
        "#{uri.scheme}://#{uri.host}#{port_part}/favicon.ico"
      else
        nil
      end
      
      {website_name, favicon_url}
    rescue
      _ ->
        {"Unknown Source", nil}
    end
  end
end
