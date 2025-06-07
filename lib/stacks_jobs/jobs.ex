defmodule StacksJobs.Workers.WebpageEnricher do
  use Oban.Worker, queue: :default, max_attempts: 3
  alias Stacks.Articles
  alias Stacks.Items
  alias Stacks.Repo
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"article_id" => article_id}}) do
    IO.puts("Processing article enrichment job for article ID #{article_id}")

    # Get the article and its associated item
    article = Articles.get_article!(article_id) |> Repo.preload(:item)
    item = article.item
    
    # Update item enrichment status to processing
    Items.update_item(item, %{"enrichment_status" => :processing})

    try do
      # Extract content using Readability
      summary = Readability.summarize(article.source_url)

      # Extract main image from webpage
      image_binary = extract_main_image(article.source_url)

      # Update article with enriched content
      Articles.update_article(article, %{
        "title" => summary.title,
        "content" => summary.article_text,
        "image" => image_binary,
        "metadata" => %{
          "article_html" => summary.article_html,
          "authors" => summary.authors,
          "extracted_at" => DateTime.utc_now()
        }
      })

      # Update item enrichment status to completed
      Items.update_item(item, %{"enrichment_status" => :completed})
    rescue
      error ->
        IO.puts("Error enriching article #{article_id}: #{inspect(error)}")
        Items.update_item(item, %{"enrichment_status" => :failed})
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

  # Extract the main image from a webpage
  defp extract_main_image(url) do
    try do
      # Fetch the webpage HTML
      case Finch.build(:get, url) |> Finch.request(Stacks.Finch) do
        {:ok, %{status: 200, body: html}} ->
          # Parse HTML to find image URL
          case find_image_url(html, url) do
            nil -> nil
            image_url -> download_image(image_url)
          end
        _ -> nil
      end
    rescue
      _ -> nil
    end
  end

  # Find the main image URL from HTML content
  defp find_image_url(html, base_url) do
    {:ok, document} = Floki.parse_document(html)
    
    # Try OpenGraph image first
    og_image = Floki.find(document, "meta[property='og:image']")
                |> Floki.attribute("content")
                |> List.first()

    if og_image do
      resolve_url(og_image, base_url)
    else
      # Try Twitter card image
      twitter_image = Floki.find(document, "meta[name='twitter:image']")
                      |> Floki.attribute("content")
                      |> List.first()

      if twitter_image do
        resolve_url(twitter_image, base_url)
      else
        # Find first large image in article content
        find_content_image(document, base_url)
      end
    end
  end

  # Find suitable image from article content
  defp find_content_image(document, base_url) do
    document
    |> Floki.find("img")
    |> Enum.find_value(fn img ->
      src = Floki.attribute(img, "src") |> List.first()
      width = Floki.attribute(img, "width") |> List.first()
      height = Floki.attribute(img, "height") |> List.first()
      
      # Filter for reasonably sized images
      if src && is_suitable_image(width, height) do
        resolve_url(src, base_url)
      end
    end)
  end

  # Check if image dimensions are suitable (width > 200px or no dimensions specified)
  defp is_suitable_image(nil, _), do: true
  defp is_suitable_image(width, _) when is_binary(width) do
    case Integer.parse(width) do
      {w, _} when w > 200 -> true
      _ -> false
    end
  end
  defp is_suitable_image(_, _), do: false

  # Resolve relative URLs to absolute URLs
  defp resolve_url("http" <> _ = url, _base_url), do: url
  defp resolve_url("//" <> _rest = url, base_url) do
    %URI{scheme: scheme} = URI.parse(base_url)
    "#{scheme}:#{url}"
  end
  defp resolve_url("/" <> _ = path, base_url) do
    %URI{scheme: scheme, host: host, port: port} = URI.parse(base_url)
    port_part = if port && port != 80 && port != 443, do: ":#{port}", else: ""
    "#{scheme}://#{host}#{port_part}#{path}"
  end
  defp resolve_url(relative_path, base_url) do
    URI.merge(base_url, relative_path) |> URI.to_string()
  end

  # Download image and return binary data
  defp download_image(image_url) do
    try do
      case Finch.build(:get, image_url) |> Finch.request(Stacks.Finch) do
        {:ok, %{status: 200, body: image_data, headers: headers}} ->
          # Check if it's actually an image
          content_type = get_content_type(headers)
          if String.starts_with?(content_type, "image/") do
            image_data
          else
            nil
          end
        _ -> nil
      end
    rescue
      _ -> nil
    end
  end

  # Extract content type from headers
  defp get_content_type(headers) do
    headers
    |> Enum.find_value("", fn
      {"content-type", value} -> value
      {"Content-Type", value} -> value
      _ -> nil
    end)
    |> String.split(";")
    |> List.first()
    |> String.trim()
  end
end
