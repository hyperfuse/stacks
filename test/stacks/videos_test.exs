defmodule Stacks.VideosTest do
  use Stacks.DataCase

  alias Stacks.Videos

  describe "videos" do
    alias Stacks.Videos.Video

    import Stacks.VideosFixtures

    @invalid_attrs %{title: nil, source_url: nil, duration: nil, thumbnail_url: nil, description: nil, video_id: nil, platform: nil, metadata: nil}

    test "list_videos/0 returns all videos" do
      video = video_fixture()
      assert Videos.list_videos() == [video]
    end

    test "get_video!/1 returns the video with given id" do
      video = video_fixture()
      assert Videos.get_video!(video.id) == video
    end

    test "create_video/1 with valid data creates a video" do
      item =
        Stacks.ItemsFixtures.item_fixture(%{
          item_type: "video",
          source_url: "https://youtube.com/watch?v=test123",
          enrichment_status: :pending
        })

      valid_attrs = %{
        title: "some title",
        source_url: "https://youtube.com/watch?v=test123",
        duration: 120,
        thumbnail_url: "https://example.com/thumbnail.jpg",
        description: "some description",
        video_id: "test123",
        platform: "youtube",
        metadata: %{},
        item_id: item.id
      }

      assert {:ok, %Video{} = video} = Videos.create_video(valid_attrs)
      assert video.title == "some title"
      assert video.source_url == "https://youtube.com/watch?v=test123"
      assert video.duration == 120
      assert video.thumbnail_url == "https://example.com/thumbnail.jpg"
      assert video.description == "some description"
      assert video.video_id == "test123"
      assert video.platform == "youtube"
      assert video.metadata == %{}
    end

    test "create_video/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Videos.create_video(@invalid_attrs)
    end

    test "update_video/2 with valid data updates the video" do
      video = video_fixture()

      update_attrs = %{
        title: "some updated title",
        source_url: "https://updated.com/video",
        duration: 150,
        thumbnail_url: "https://updated.com/thumbnail.jpg",
        description: "some updated description",
        video_id: "updated123",
        platform: "vimeo",
        metadata: %{updated: true}
      }

      assert {:ok, %Video{} = video} = Videos.update_video(video, update_attrs)
      assert video.title == "some updated title"
      assert video.source_url == "https://updated.com/video"
      assert video.duration == 150
      assert video.thumbnail_url == "https://updated.com/thumbnail.jpg"
      assert video.description == "some updated description"
      assert video.video_id == "updated123"
      assert video.platform == "vimeo"
      assert video.metadata == %{updated: true}
    end

    test "update_video/2 with invalid data returns error changeset" do
      video = video_fixture()
      assert {:error, %Ecto.Changeset{}} = Videos.update_video(video, @invalid_attrs)
      assert video == Videos.get_video!(video.id)
    end

    test "delete_video/1 deletes the video" do
      video = video_fixture()
      assert {:ok, %Video{}} = Videos.delete_video(video)
      assert_raise Ecto.NoResultsError, fn -> Videos.get_video!(video.id) end
    end

    test "change_video/1 returns a video changeset" do
      video = video_fixture()
      assert %Ecto.Changeset{} = Videos.change_video(video)
    end
  end
end