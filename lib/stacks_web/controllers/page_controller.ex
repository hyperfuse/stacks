defmodule StacksWeb.PageController do
  use StacksWeb, :controller

  alias Stacks.Items

  def home(conn, _params) do
    items = Items.list_inbox_items_with_associations()
    render(conn, :home, items: items)
  end

  def articles(conn, _params) do
    articles = Items.list_items_with_associations()
    |> Enum.filter(&(&1.item_type == "article" && &1.article))
    render(conn, :articles, items: articles)
  end

  def videos(conn, _params) do
    videos = Items.list_items_with_associations()
    |> Enum.filter(&(&1.item_type == "video" && &1.video))
    render(conn, :videos, items: videos)
  end

  def archives(conn, _params) do
    items = Items.list_archived_items_with_associations()
    render(conn, :archives, items: items)
  end

  def item(conn, %{"id" => id}) do
    item = Items.get_item_with_associations!(id)
    render(conn, :item, item: item)
  end
end
