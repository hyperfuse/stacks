defmodule StacksWeb.VideoController do
  use StacksWeb, :controller

  alias Stacks.Videos
  alias Stacks.Videos.Video
  alias Stacks.Items
  alias StacksJobs.Workers.Enricher

  action_fallback StacksWeb.FallbackController

  def index(conn, _params) do
    videos = Videos.list_videos()
    render(conn, :index, videos: videos)
  end

  def create(conn, %{"video" => video_params}) do
    # First create an item
    item_params = %{
      "item_type" => "video",
      "source_url" => video_params["source_url"]
    }

    case Items.create_item(item_params) do
      {:ok, item} ->
        # Then create the video linked to the item
        video_params_with_item = Map.put(video_params, "item_id", item.id)

        case Videos.create_video(video_params_with_item) do
          {:ok, video} ->
            # Enqueue the enrichment job using the item_id
            Enricher.insert(%{"item_id" => item.id})

            conn
            |> put_status(:created)
            |> put_resp_header("location", ~p"/api/videos/#{video}")
            |> render(:show, video: video)

          {:error, changeset} ->
            # Clean up the item if video creation fails
            Items.delete_item(item)
            {:error, changeset}
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def show(conn, %{"id" => id}) do
    video = Videos.get_video!(id)
    render(conn, :show, video: video)
  end

  def update(conn, %{"id" => id, "video" => video_params}) do
    video = Videos.get_video!(id)

    with {:ok, %Video{} = video} <- Videos.update_video(video, video_params) do
      render(conn, :show, video: video)
    end
  end

  def delete(conn, %{"id" => id}) do
    video = Videos.get_video!(id)

    with {:ok, %Video{}} <- Videos.delete_video(video) do
      send_resp(conn, :no_content, "")
    end
  end
end