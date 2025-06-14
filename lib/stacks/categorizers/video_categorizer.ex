defmodule Stacks.Categorizers.VideoCategorizer do
  @moduledoc """
  Categorizer that identifies videos based on URL patterns and meta tags from major video platforms.
  """
  
  @behaviour Stacks.Categorizer

  @impl Stacks.Categorizer
  def categorize(url, html) do
    try do
      if has_video_indicators?(url, html) do
        metadata = extract_video_metadata(url, html)
        {:ok, {:video, metadata}}
      else
        {:ok, nil}
      end
    rescue
      _ ->
        {:ok, nil}
    end
  end

  # Check if this URL or content indicates a video
  defp has_video_indicators?(url, html) do
    url_suggests_video?(url) || html_suggests_video?(html)
  end

  # Check if URL patterns suggest this is a video
  defp url_suggests_video?(url) do
    video_patterns = [
      # YouTube
      ~r/youtube\.com\/watch/i,
      ~r/youtu\.be\//i,
      ~r/youtube\.com\/embed\//i,
      # Vimeo
      ~r/vimeo\.com\/\d+/i,
      ~r/player\.vimeo\.com\/video\//i,
      # TikTok
      ~r/tiktok\.com\/.+\/video\//i,
      ~r/tiktok\.com\/t\//i,
      # Instagram
      ~r/instagram\.com\/p\//i,
      ~r/instagram\.com\/reel\//i,
      ~r/instagram\.com\/tv\//i,
      # Twitter/X
      ~r/twitter\.com\/.+\/status\//i,
      ~r/x\.com\/.+\/status\//i,
      # Twitch
      ~r/twitch\.tv\/videos\//i,
      ~r/clips\.twitch\.tv\//i,
      # Other platforms
      ~r/dailymotion\.com\/video\//i,
      ~r/wistia\.com\/medias\//i,
      ~r/brightcove\.com\//i,
      ~r/streamable\.com\//i,
      # Generic video file extensions
      ~r/\.(mp4|avi|mov|wmv|flv|webm|mkv|m4v)$/i
    ]
    
    Enum.any?(video_patterns, &Regex.match?(&1, url))
  end

  # Check if HTML content suggests this is a video
  defp html_suggests_video?(html) do
    {:ok, document} = Floki.parse_document(html)
    
    # Check for video meta tags
    has_video_meta_tags?(document) || has_video_elements?(document)
  end

  # Check for video-specific meta tags
  defp has_video_meta_tags?(document) do
    # OpenGraph video type
    og_type = Floki.find(document, "meta[property='og:type']")
              |> Floki.attribute("content")
              |> List.first()
    
    # Check for video URL in meta tags
    has_video_url = !Enum.empty?(Floki.find(document, "meta[property='og:video']")) ||
                    !Enum.empty?(Floki.find(document, "meta[property='og:video:url']")) ||
                    !Enum.empty?(Floki.find(document, "meta[name='twitter:player']"))
    
    # Check for JSON-LD structured data indicating a video
    json_ld_scripts = Floki.find(document, "script[type='application/ld+json']")
    has_video_json_ld = Enum.any?(json_ld_scripts, fn script ->
      script_content = Floki.text(script)
      String.contains?(script_content, "VideoObject") || 
      String.contains?(script_content, "VideoCreativeWork") ||
      String.contains?(script_content, "\"@type\":\"Video")
    end)
    
    og_type == "video" || has_video_url || has_video_json_ld
  end

  # Check for HTML video elements
  defp has_video_elements?(document) do
    # Look for HTML5 video elements
    has_video_element = !Enum.empty?(Floki.find(document, "video"))
    
    # Look for common video embed iframes
    iframes = Floki.find(document, "iframe")
    has_video_iframe = Enum.any?(iframes, fn iframe ->
      src = Floki.attribute(iframe, "src") |> List.first() || ""
      String.contains?(src, "youtube") || 
      String.contains?(src, "vimeo") || 
      String.contains?(src, "player") ||
      String.contains?(src, "embed")
    end)
    
    has_video_element || has_video_iframe
  end

  # Extract video metadata from URL and HTML
  defp extract_video_metadata(url, html) do
    {:ok, document} = Floki.parse_document(html)
    
    # Extract basic info
    title = extract_title(document)
    description = extract_description(document)
    duration = extract_duration(document)
    thumbnail_url = extract_thumbnail(document, url)
    {platform, video_id} = extract_platform_info(url)
    
    # Extract source website and favicon
    {source_website, favicon_url} = extract_website_info(url, document)
    
    %{
      "detected_by" => "video_categorizer",
      "title" => title,
      "description" => description,
      "duration" => duration,
      "thumbnail_url" => thumbnail_url,
      "video_id" => video_id,
      "platform" => platform,
      "source_website" => source_website,
      "favicon_url" => favicon_url,
      "extracted_at" => DateTime.utc_now()
    }
  end

  # Extract video title
  defp extract_title(document) do
    # Try different meta tags for video title
    og_title = Floki.find(document, "meta[property='og:title']")
               |> Floki.attribute("content")
               |> List.first()
    
    twitter_title = Floki.find(document, "meta[name='twitter:title']")
                    |> Floki.attribute("content")
                    |> List.first()
    
    page_title = Floki.find(document, "title")
                 |> Floki.text()
    
    og_title || twitter_title || page_title || "Untitled Video"
  end

  # Extract video description
  defp extract_description(document) do
    # Try different meta tags for description
    og_description = Floki.find(document, "meta[property='og:description']")
                     |> Floki.attribute("content")
                     |> List.first()
    
    meta_description = Floki.find(document, "meta[name='description']")
                       |> Floki.attribute("content")
                       |> List.first()
    
    twitter_description = Floki.find(document, "meta[name='twitter:description']")
                          |> Floki.attribute("content")
                          |> List.first()
    
    og_description || meta_description || twitter_description
  end

  # Extract video duration (in seconds)
  defp extract_duration(document) do
    # Try to find duration in JSON-LD or meta tags
    json_ld_scripts = Floki.find(document, "script[type='application/ld+json']")
    
    duration = Enum.find_value(json_ld_scripts, fn script ->
      script_content = Floki.text(script)
      case Jason.decode(script_content) do
        {:ok, data} -> extract_duration_from_json_ld(data)
        _ -> nil
      end
    end)
    
    # Try og:video:duration meta tag
    duration || 
    (Floki.find(document, "meta[property='og:video:duration']")
     |> Floki.attribute("content")
     |> List.first()
     |> parse_duration())
  end

  # Extract duration from JSON-LD structured data
  defp extract_duration_from_json_ld(data) when is_map(data) do
    cond do
      Map.has_key?(data, "duration") -> parse_duration(data["duration"])
      Map.has_key?(data, "@graph") -> extract_duration_from_json_ld(data["@graph"])
      true -> nil
    end
  end

  defp extract_duration_from_json_ld(data) when is_list(data) do
    Enum.find_value(data, fn item ->
      extract_duration_from_json_ld(item)
    end)
  end

  defp extract_duration_from_json_ld(_), do: nil

  # Parse duration string (ISO 8601 format like PT1M23S or seconds)
  defp parse_duration(nil), do: nil
  defp parse_duration(""), do: nil
  
  defp parse_duration(duration_str) when is_binary(duration_str) do
    cond do
      # ISO 8601 format (PT1M23S)
      String.starts_with?(duration_str, "PT") ->
        parse_iso8601_duration(duration_str)
      
      # Just seconds
      String.match?(duration_str, ~r/^\d+$/) ->
        String.to_integer(duration_str)
      
      true -> nil
    end
  end

  defp parse_duration(duration) when is_integer(duration), do: duration
  defp parse_duration(_), do: nil

  # Parse ISO 8601 duration format (PT1H2M3S)
  defp parse_iso8601_duration(duration_str) do
    # Remove PT prefix
    duration_str = String.replace_prefix(duration_str, "PT", "")
    
    # Extract hours, minutes, seconds
    hours = Regex.run(~r/(\d+)H/, duration_str, capture: :all_but_first) |> get_number()
    minutes = Regex.run(~r/(\d+)M/, duration_str, capture: :all_but_first) |> get_number()
    seconds = Regex.run(~r/(\d+)S/, duration_str, capture: :all_but_first) |> get_number()
    
    (hours * 3600) + (minutes * 60) + seconds
  rescue
    _ -> nil
  end

  defp get_number([num_str]), do: String.to_integer(num_str)
  defp get_number(_), do: 0

  # Extract video thumbnail URL
  defp extract_thumbnail(document, base_url) do
    # Try different meta tags for thumbnail
    og_image = Floki.find(document, "meta[property='og:image']")
               |> Floki.attribute("content")
               |> List.first()
    
    twitter_image = Floki.find(document, "meta[name='twitter:image']")
                    |> Floki.attribute("content")
                    |> List.first()
    
    thumbnail_url = og_image || twitter_image
    
    if thumbnail_url do
      resolve_url(thumbnail_url, base_url)
    else
      nil
    end
  end

  # Extract platform and video ID from URL
  defp extract_platform_info(url) do
    cond do
      String.contains?(url, "youtube.com") || String.contains?(url, "youtu.be") ->
        {"youtube", extract_youtube_id(url)}
      
      String.contains?(url, "vimeo.com") ->
        {"vimeo", extract_vimeo_id(url)}
      
      String.contains?(url, "tiktok.com") ->
        {"tiktok", extract_tiktok_id(url)}
      
      String.contains?(url, "instagram.com") ->
        {"instagram", extract_instagram_id(url)}
      
      String.contains?(url, "twitter.com") || String.contains?(url, "x.com") ->
        {"twitter", extract_twitter_id(url)}
      
      String.contains?(url, "twitch.tv") ->
        {"twitch", extract_twitch_id(url)}
      
      true ->
        {extract_domain(url), nil}
    end
  end

  # Extract YouTube video ID
  defp extract_youtube_id(url) do
    cond do
      match = Regex.run(~r/[?&]v=([^&]+)/, url) -> Enum.at(match, 1)
      match = Regex.run(~r/youtu\.be\/([^?]+)/, url) -> Enum.at(match, 1)
      match = Regex.run(~r/embed\/([^?]+)/, url) -> Enum.at(match, 1)
      true -> nil
    end
  end

  # Extract Vimeo video ID
  defp extract_vimeo_id(url) do
    case Regex.run(~r/vimeo\.com\/(\d+)/, url) do
      [_, id] -> id
      _ -> nil
    end
  end

  # Extract TikTok video ID
  defp extract_tiktok_id(url) do
    case Regex.run(~r/video\/(\d+)/, url) do
      [_, id] -> id
      _ -> nil
    end
  end

  # Extract Instagram media ID
  defp extract_instagram_id(url) do
    case Regex.run(~r/\/p\/([^\/\?]+)/, url) do
      [_, id] -> id
      _ -> nil
    end
  end

  # Extract Twitter status ID
  defp extract_twitter_id(url) do
    case Regex.run(~r/status\/(\d+)/, url) do
      [_, id] -> id
      _ -> nil
    end
  end

  # Extract Twitch video/clip ID
  defp extract_twitch_id(url) do
    cond do
      match = Regex.run(~r/videos\/(\d+)/, url) -> Enum.at(match, 1)
      match = Regex.run(~r/clips\.twitch\.tv\/([^\/\?]+)/, url) -> Enum.at(match, 1)
      true -> nil
    end
  end

  # Extract domain from URL
  defp extract_domain(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) ->
        host
        |> String.replace_prefix("www.", "")
        |> String.split(".")
        |> List.first()
        |> String.capitalize()
      _ -> "Unknown"
    end
  end

  # Extract website name and favicon URL from a webpage
  defp extract_website_info(url, document) do
    try do
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
    # Try og:site_name first
    og_site_name =
      Floki.find(document, "meta[property='og:site_name']")
      |> Floki.attribute("content")
      |> List.first()

    if og_site_name && og_site_name != "" do
      og_site_name
    else
      # Fallback to domain name
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

  # Extract favicon URL from HTML document
  defp extract_favicon_url(document, base_url) do
    # Try different favicon link types
    favicon_selectors = [
      "link[rel='icon'][type='image/png']",
      "link[rel='icon'][type='image/svg+xml']",
      "link[rel='icon']",
      "link[rel='shortcut icon']"
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
end