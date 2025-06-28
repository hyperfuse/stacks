defmodule StacksWeb.ItemLive do
  use StacksWeb, :live_view

  alias Stacks.Items

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    item = Items.get_item_with_associations!(id)
    {:ok, assign(socket, :item, item)}
  end

  @impl true
  def handle_event("archive", _params, socket) do
    case Items.archive_item(socket.assigns.item) do
      {:ok, updated_item} ->
        {:noreply, assign(socket, :item, updated_item)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("unarchive", _params, socket) do
    case Items.unarchive_item(socket.assigns.item) do
      {:ok, updated_item} ->
        {:noreply, assign(socket, :item, updated_item)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete", _params, socket) do
    item = socket.assigns.item
    redirect_path = if item.archived, do: ~p"/archives", else: ~p"/"

    case Items.delete_item(item) do
      {:ok, _deleted_item} ->
        {:noreply, redirect(socket, to: redirect_path)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  defp format_duration(seconds) when is_integer(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    seconds = rem(seconds, 60)

    cond do
      hours > 0 ->
        "#{hours}:#{String.pad_leading("#{minutes}", 2, "0")}:#{String.pad_leading("#{seconds}", 2, "0")}"

      minutes > 0 ->
        "#{minutes}:#{String.pad_leading("#{seconds}", 2, "0")}"

      true ->
        "0:#{String.pad_leading("#{seconds}", 2, "0")}"
    end
  end

  defp format_duration(_), do: "Unknown"
end
