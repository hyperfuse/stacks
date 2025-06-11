defmodule Stacks.Categorizer do
  @moduledoc """
  Behavior for categorizing web content.
  
  A categorizer takes a document loaded using Finch and parses it to return a type.
  The first categorizer to return a non-nil result should be used.
  """

  @doc """
  Categorizes a document based on its URL and HTML content.
  
  ## Parameters
  - `url`: The URL of the document
  - `html`: The HTML content of the document
  
  ## Returns
  - `{:ok, {type, metadata}}` - Successfully categorized with type and metadata
  - `{:ok, nil}` - This categorizer cannot categorize this document
  """
  @callback categorize(url :: String.t(), html :: String.t()) ::
              {:ok, {atom(), map()} | nil}

  @doc """
  Categorizes a document by fetching it first, then analyzing the content.
  
  This is a convenience function that handles the Finch request and delegates
  to the categorize/2 callback.
  """
  def categorize_url(categorizer, url) do
    case Finch.build(:get, url) |> Finch.request(Stacks.Finch) do
      {:ok, %{status: 200, body: html}} ->
        categorizer.categorize(url, html)
      
      _ ->
        {:ok, nil}
    end
  rescue
    _ ->
      {:ok, nil}
  end

  @doc """
  Attempts to categorize a document using multiple categorizers.
  
  Returns the result from the first categorizer that successfully categorizes
  the document (returns something other than {:ok, nil}).
  """
  def categorize_with_multiple(categorizers, url, html) do
    Enum.find_value(categorizers, {:ok, nil}, fn categorizer ->
      case categorizer.categorize(url, html) do
        {:ok, nil} -> nil
        result -> result
      end
    end)
  end
end