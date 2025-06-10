defmodule StacksWeb.ItemJSON do
  alias Stacks.Items.Item

  @doc """
  Renders a list of items.
  """
  def index(%{items: items}) do
    %{data: for(item <- items, do: data(item))}
  end

  @doc """
  Renders a single item.
  """
  def show(%{item: item}) do
    %{data: data(item)}
  end

  defp data(%Item{} = item) do
    %{
      id: item.id,
      item_type: item.item_type,
      source_url: item.source_url,
      text_content: item.text_content,
      metadata: item.metadata,
      inserted_at: item.inserted_at,
      updated_at: item.updated_at
    }
  end
end
