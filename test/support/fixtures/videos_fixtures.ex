defmodule Stacks.VideosFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Stacks.Videos` context.
  """

  @doc """
  Generate a video.
  """
  def video_fixture(attrs \\ %{}) do
    # Create an item first since video requires it
    item =
      Stacks.ItemsFixtures.item_fixture(%{
        item_type: "video",
        source_url: "https://youtube.com/watch?v=example123",
        enrichment_status: :pending
      })

    {:ok, video} =
      attrs
      |> Enum.into(%{
        title: "some video title",
        source_url: "https://youtube.com/watch?v=example123",
        duration: 120,
        thumbnail_url: "https://example.com/thumbnail.jpg",
        description: "some video description",
        video_id: "example123",
        platform: "youtube",
        metadata: %{},
        item_id: item.id
      })
      |> Stacks.Videos.create_video()

    video
  end
end