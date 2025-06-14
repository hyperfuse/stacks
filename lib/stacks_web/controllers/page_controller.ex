defmodule StacksWeb.PageController do
  use StacksWeb, :controller

  alias Stacks.Items

  def home(conn, _params) do
    items = Items.list_items_with_associations()
    render(conn, :home, items: items)
  end

  def item(conn, %{"id" => id}) do
    item = Items.get_item_with_associations!(id)
    render(conn, :item, item: item)
  end
end
