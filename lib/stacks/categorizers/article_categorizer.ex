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
        {:ok, {:article, %{detected_by: "article_categorizer"}}}
      else
        {:ok, nil}
      end
    rescue
      _ ->
        {:ok, nil}
    end
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
end