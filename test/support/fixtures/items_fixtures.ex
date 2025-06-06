defmodule Stacks.ItemsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Stacks.Items` context.
  """

  @doc """
  Generate a item.
  """
  def item_fixture(attrs \\ %{}) do
    {:ok, item} =
      attrs
      |> Enum.into(%{
        item_type: "some item_type",
        metadata: %{},
        source_url: "some source_url",
        text_content: "some text_content",
        enrichment_status: :pending
      })
      |> Stacks.Items.create_item()

    item
  end
end
