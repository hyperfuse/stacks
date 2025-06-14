defmodule StacksWeb.VideoControllerTest do
  use StacksWeb.ConnCase

  import Stacks.VideosFixtures

  alias Stacks.Videos.Video

  @create_attrs %{
    title: "some video title",
    source_url: "https://youtube.com/watch?v=test123",
    duration: 120,
    thumbnail_url: "https://example.com/thumbnail.jpg",
    description: "some video description",
    video_id: "test123",
    platform: "youtube",
    metadata: %{}
  }
  @update_attrs %{
    title: "some updated video title",
    source_url: "https://updated.com/video",
    duration: 150,
    thumbnail_url: "https://updated.com/thumbnail.jpg",
    description: "some updated video description",
    video_id: "updated123",
    platform: "vimeo",
    metadata: %{updated: true}
  }
  @invalid_attrs %{title: nil, source_url: nil, duration: nil, thumbnail_url: nil, description: nil, video_id: nil, platform: nil, metadata: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all videos", %{conn: conn} do
      conn = get(conn, ~p"/api/videos")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create video" do
    test "renders video when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/videos", video: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/videos/#{id}")

      assert %{
               "id" => ^id,
               "title" => "some video title",
               "source_url" => "https://youtube.com/watch?v=test123",
               "duration" => 120,
               "thumbnail_url" => "https://example.com/thumbnail.jpg",
               "description" => "some video description",
               "video_id" => "test123",
               "platform" => "youtube",
               "metadata" => %{}
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/videos", video: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update video" do
    setup [:create_video]

    test "renders video when data is valid", %{conn: conn, video: %Video{id: id} = video} do
      conn = put(conn, ~p"/api/videos/#{video}", video: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/videos/#{id}")

      assert %{
               "id" => ^id,
               "title" => "some updated video title",
               "source_url" => "https://updated.com/video",
               "duration" => 150,
               "thumbnail_url" => "https://updated.com/thumbnail.jpg",
               "description" => "some updated video description",
               "video_id" => "updated123",
               "platform" => "vimeo",
               "metadata" => %{"updated" => true}
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, video: video} do
      conn = put(conn, ~p"/api/videos/#{video}", video: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete video" do
    setup [:create_video]

    test "deletes chosen video", %{conn: conn, video: video} do
      conn = delete(conn, ~p"/api/videos/#{video}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/videos/#{video}")
      end
    end
  end

  defp create_video(_) do
    video = video_fixture()
    %{video: video}
  end
end