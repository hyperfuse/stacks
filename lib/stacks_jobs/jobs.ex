defmodule StacksJobs.Workers.Enricher do
  use Oban.Worker, queue: :default, max_attempts: 3
  alias Stacks.Articles
  alias Stacks.Items
  alias Stacks.Repo
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

          # Extract content using Readability
          summary = Readability.summarize(item.source_url)

          # Extract main image from webpage
          image_binary = extract_main_image(item.source_url)

          # Extract source website and favicon
          {source_website, favicon_url} = extract_website_info(item.source_url)

          # Create article record with categorizer metadata
          article_metadata =
            Map.merge(
              %{
                "authors" => summary.authors,
                "extracted_at" => DateTime.utc_now()
              },
              metadata
            )

          {:ok, _article} =
            Articles.create_article(%{
              "item_id" => item.id,
              "source_url" => item.source_url,
              "title" => summary.title,
              "html_content" => summary.article_html,
              "text_content" => summary.article_text,
              "image" => image_binary,
              "metadata" => article_metadata
            })

          # Update item with website info and enrichment status
          Items.update_item(item, %{
            "source_website" => source_website,
            "favicon_url" => favicon_url,
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

  # Support legacy format for backward compatibility
  # TODO remove this
  def perform(%Oban.Job{args: %{"article_id" => article_id}}) do
    # Get article and use its item_id
    article = Articles.get_article!(article_id) |> Repo.preload(:item)
    perform(%Oban.Job{args: %{"item_id" => article.item.id}})
  end

  # Support legacy format for backward compatibility
  # TODO remove this
  def perform(%Oban.Job{args: %{"id" => id}}) do
    perform(%Oban.Job{args: %{"item_id" => id}})
  end

  def insert(%{"item_id" => item_id}) do
    StacksJobs.Workers.Enricher.new(%{"item_id" => item_id})
    |> Oban.insert()
  end

  # Support legacy format for backward compatibility
  # TODO remove this
  def insert(%{"article_id" => article_id}) do
    # Get article and use its item_id
    article = Articles.get_article!(article_id) |> Repo.preload(:item)
    insert(%{"item_id" => article.item.id})
  end

  # Support legacy format for backward compatibility
  #  TODO remove this
  def insert(%{"id" => id}) do
    insert(%{"item_id" => id})
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

        _ ->
          nil
      end
    rescue
      _ -> nil
    end
  end

  # Find the main image URL from HTML content
  defp find_image_url(html, base_url) do
    {:ok, document} = Floki.parse_document(html)

    # Try OpenGraph image first
    og_image =
      Floki.find(document, "meta[property='og:image']")
      |> Floki.attribute("content")
      |> List.first()

    if og_image do
      resolve_url(og_image, base_url)
    else
      # Try Twitter card image
      twitter_image =
        Floki.find(document, "meta[name='twitter:image']")
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

        _ ->
          nil
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

  # Extract website name and favicon URL from a webpage
  defp extract_website_info(url) do
    try do
      case Finch.build(:get, url) |> Finch.request(Stacks.Finch) do
        {:ok, %{status: 200, body: html}} ->
          {:ok, document} = Floki.parse_document(html)

          # Extract website name
          website_name = extract_website_name(document, url)

          # Extract favicon URL
          favicon_url = extract_favicon_url(document, url)

          {website_name, favicon_url}

        _ ->
          # Fallback to domain from URL
          uri = URI.parse(url)
          domain = uri.host || "Unknown Source"
          {domain, nil}
      end
    rescue
      _ ->
        # Fallback to domain from URL
        uri = URI.parse(url)
        domain = uri.host || "Unknown Source"
        {domain, nil}
    end
  end

  # Extract website name from HTML document
  defp extract_website_name(document, url) do
    # Try different methods to get website name, in order of preference

    # 1. Try og:site_name
    og_site_name =
      Floki.find(document, "meta[property='og:site_name']")
      |> Floki.attribute("content")
      |> List.first()

    if og_site_name && og_site_name != "" do
      og_site_name
    else
      # 2. Try twitter:site
      twitter_site =
        Floki.find(document, "meta[name='twitter:site']")
        |> Floki.attribute("content")
        |> List.first()

      if twitter_site && twitter_site != "" do
        # Remove @ symbol if present
        String.replace(twitter_site, "@", "")
      else
        # 3. Try to extract from title tag
        title =
          Floki.find(document, "title")
          |> Floki.text()

        # Look for common patterns like "Title - Site Name" or "Title | Site Name"
        cond do
          String.contains?(title, " - ") ->
            title |> String.split(" - ") |> List.last() |> String.trim()

          String.contains?(title, " | ") ->
            title |> String.split(" | ") |> List.last() |> String.trim()

          true ->
            # 4. Fallback to domain name
            uri = URI.parse(url)
            domain = uri.host || "Unknown Source"

            # Clean up common prefixes
            domain
            |> String.replace_prefix("www.", "")
            |> String.split(".")
            |> List.first()
            |> String.capitalize()
        end
      end
    end
  end

  # Extract favicon URL from HTML document
  defp extract_favicon_url(document, base_url) do
    # Try different favicon link types, in order of preference
    favicon_selectors = [
      "link[rel='icon'][type='image/png']",
      "link[rel='icon'][type='image/svg+xml']",
      "link[rel='icon']",
      "link[rel='shortcut icon']",
      "link[rel='apple-touch-icon']"
    ]

    favicon_url =
      Enum.find_value(favicon_selectors, fn selector ->
        Floki.find(document, selector)
        |> Floki.attribute("href")
        |> List.first()
      end)

    cond do
      favicon_url && favicon_url != "" ->
        resolve_url(favicon_url, base_url)

      true ->
        # Fallback to /favicon.ico
        uri = URI.parse(base_url)

        if uri.scheme && uri.host do
          port_part =
            if uri.port && uri.port != 80 && uri.port != 443, do: ":#{uri.port}", else: ""

          "#{uri.scheme}://#{uri.host}#{port_part}/favicon.ico"
        else
          nil
        end
    end
  end
end
