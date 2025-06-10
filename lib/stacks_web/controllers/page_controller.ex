defmodule StacksWeb.PageController do
  use StacksWeb, :controller

  alias Stacks.Items

  def home(conn, _params) do
    items = Items.list_items_with_articles()
    render(conn, :home, items: items)
  end
end
