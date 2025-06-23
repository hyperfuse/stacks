defmodule StacksWeb.ItemController do
  use StacksWeb, :controller

  alias Stacks.Items
  alias Stacks.Items.Item

  action_fallback StacksWeb.FallbackController

  def index(conn, _params) do
    items = Items.list_items()
    render(conn, :index, items: items)
  end

  def create(conn, %{"item" => item_params}) do
    IO.inspect(item_params)

    case Items.create_or_get_item(item_params) do
      {:ok, %Item{} = item} ->
        {:ok, _job} = StacksJobs.Workers.Enricher.insert(%{"item_id" => item.id})

        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/items/#{item}")
        |> render(:show, item: item)

      {:existing, %Item{} = item} ->
        conn
        |> put_status(:ok)
        |> render(:show, item: item)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(StacksWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    item = Items.get_item!(id)
    render(conn, :show, item: item)
  end

  def update(conn, %{"id" => id, "item" => item_params}) do
    item = Items.get_item!(id)

    with {:ok, %Item{} = item} <- Items.update_item(item, item_params) do
      render(conn, :show, item: item)
    end
  end

  def delete(conn, %{"id" => id}) do
    item = Items.get_item!(id)

    with {:ok, %Item{}} <- Items.delete_item(item) do
      send_resp(conn, :no_content, "")
    end
  end

  def archive(conn, %{"id" => id}) do
    item = Items.get_item!(id)

    with {:ok, %Item{} = item} <- Items.archive_item(item) do
      render(conn, :show, item: item)
    end
  end

  def unarchive(conn, %{"id" => id}) do
    item = Items.get_item!(id)

    with {:ok, %Item{} = item} <- Items.unarchive_item(item) do
      render(conn, :show, item: item)
    end
  end
end
