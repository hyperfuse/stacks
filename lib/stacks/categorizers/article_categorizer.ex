defmodule Stacks.Categorizers.ArticleCategorizer do
  @moduledoc """
  Categorizer that identifies articles based on URL patterns, meta tags, and content structure.
  """
  
  @behaviour Stacks.Categorizer

  @impl Stacks.Categorizer
  def categorize(url, html) do
    try do
      {:ok, document} = Floki.parse_document(html)
      
      if has_article_indicators?(document, url) do
        # Extract all article metadata
        metadata = extract_article_metadata(url, html)
        {:ok, {:article, metadata}}
      else
        {:ok, nil}
      end
    rescue
      _ ->
        {:ok, nil}
    end
  end

  # Extract comprehensive article metadata
  defp extract_article_metadata(url, html) do
    # Extract content using Readability
    summary = Readability.summarize(url)
    
    # Extract main image from webpage
    image_binary = extract_main_image(url, html)
    
    # Extract source website and favicon
    {source_website, favicon_url} = extract_website_info(url, html)
    
    %{
      "detected_by" => "article_categorizer",
      "title" => summary.title,
      "html_content" => summary.article_html,
      "text_content" => summary.article_text,
      "authors" => summary.authors,
      "image" => image_binary,
      "source_website" => source_website,
      "favicon_url" => favicon_url,
      "extracted_at" => DateTime.utc_now()
    }
  end

  # Check for various indicators that suggest this is an article
  defp has_article_indicators?(document, url) do
    # Check URL patterns that suggest articles
    url_suggests_article = url_suggests_article?(url)
    
    # Check for article-specific meta tags
    has_article_meta = has_article_meta_tags?(document)
    
    # Check for structured content that suggests an article
    has_article_structure = has_article_structure?(document)
    
    # Check content length (articles typically have substantial text)
    has_sufficient_content = has_sufficient_content?(document)
    
    # Consider it an article if any strong indicators are present
    url_suggests_article || has_article_meta || (has_article_structure && has_sufficient_content)
  end

  # Check if URL patterns suggest this is an article
  defp url_suggests_article?(url) do
    # Common patterns in article URLs
    article_patterns = [
      ~r/\/article[s]?\//i,
      ~r/\/blog\//i,
      ~r/\/post[s]?\//i,
      ~r/\/news\//i,
      ~r/\/story\//i,
      ~r/\/\d{4}\/\d{2}\/\d{2}\//,  # Date pattern like /2023/12/01/
      ~r/-\d{4}-\d{2}-\d{2}/,       # Date pattern like -2023-12-01
      ~r/\/read\//i,
      ~r/\/content\//i
    ]
    
    # Exclude patterns that are unlikely to be articles
    non_article_patterns = [
      ~r/\/api\//i,
      ~r/\/admin\//i,
      ~r/\/login\//i,
      ~r/\/signup\//i,
      ~r/\/register\//i,
      ~r/\/search\//i,
      ~r/\/category\//i,
      ~r/\/tag[s]?\//i,
      ~r/\/user[s]?\//i,
      ~r/\/profile[s]?\//i,
      ~r/\.(pdf|doc|docx|xls|xlsx|ppt|pptx|zip|rar|exe|dmg)$/i
    ]
    
    # Check if any non-article patterns match (exclude if they do)
    if Enum.any?(non_article_patterns, &Regex.match?(&1, url)) do
      false
    else
      # Check if any article patterns match
      Enum.any?(article_patterns, &Regex.match?(&1, url))
    end
  end

  # Check for article-specific meta tags
  defp has_article_meta_tags?(document) do
    # OpenGraph article type
    og_type = Floki.find(document, "meta[property='og:type']")
              |> Floki.attribute("content")
              |> List.first()
    
    # Check for JSON-LD structured data indicating an article
    json_ld_scripts = Floki.find(document, "script[type='application/ld+json']")
    has_article_json_ld = Enum.any?(json_ld_scripts, fn script ->
      script_content = Floki.text(script)
      String.contains?(script_content, "Article") || 
      String.contains?(script_content, "NewsArticle") ||
      String.contains?(script_content, "BlogPosting")
    end)
    
    # Check for article-specific meta tags
    has_author = !Enum.empty?(Floki.find(document, "meta[name='author']")) ||
                 !Enum.empty?(Floki.find(document, "meta[property='article:author']"))
    
    has_published_date = !Enum.empty?(Floki.find(document, "meta[property='article:published_time']")) ||
                        !Enum.empty?(Floki.find(document, "meta[name='publish_date']")) ||
                        !Enum.empty?(Floki.find(document, "time[datetime]"))
    
    og_type == "article" || has_article_json_ld || (has_author && has_published_date)
  end

  # Check for HTML structure that suggests an article
  defp has_article_structure?(document) do
    # Look for semantic HTML5 article elements
    has_article_element = !Enum.empty?(Floki.find(document, "article"))
    
    # Look for common article container classes/IDs
    article_selectors = [
      "[class*='article']",
      "[class*='post']", 
      "[class*='content']",
      "[class*='entry']",
      "[id*='article']",
      "[id*='post']",
      "[id*='content']",
      "[id*='entry']"
    ]
    
    has_article_container = Enum.any?(article_selectors, fn selector ->
      !Enum.empty?(Floki.find(document, selector))
    end)
    
    has_article_element || has_article_container
  end

  # Check if the document has sufficient content to be an article
  defp has_sufficient_content?(document) do
    # Extract text content and check length
    text_content = Floki.text(document)
    text_length = String.length(String.trim(text_content))
    
    # Articles typically have at least 200 characters of content
    text_length > 200
  end

  # Extract the main image from a webpage
  defp extract_main_image(url, html) do
    try do
      # Parse HTML to find image URL
      case find_image_url(html, url) do
        nil -> nil
        image_url -> download_image(image_url)
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
  defp extract_website_info(url, html) do
    try do
      {:ok, document} = Floki.parse_document(html)

      # Extract website name
      website_name = extract_website_name(document, url)

      # Extract favicon URL
      favicon_url = extract_favicon_url(document, url)

      {website_name, favicon_url}
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