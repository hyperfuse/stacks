defmodule StacksWeb.VideoJSON do
  alias Stacks.Videos.Video

  @doc """
  Renders a list of videos.
  """
  def index(%{videos: videos}) do
    %{data: for(video <- videos, do: data(video))}
  end

  @doc """
  Renders a single video.
  """
  def show(%{video: video}) do
    %{data: data(video)}
  end

  defp data(%Video{} = video) do
    %{
      id: video.id,
      title: video.title,
      source_url: video.source_url,
      duration: video.duration,
      thumbnail_url: video.thumbnail_url,
      description: video.description,
      video_id: video.video_id,
      platform: video.platform,
      metadata: video.metadata,
      item_id: video.item_id,
      user_id: video.user_id
    }
  end
end