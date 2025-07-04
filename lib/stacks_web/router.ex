defmodule StacksWeb.Router do
  alias ItemController
  use StacksWeb, :router

  import Oban.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {StacksWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug Corsica, origins: "*"
    plug :accepts, ["json"]
    # Allow cross-origin requests in dev
    plug Corsica, origins: "*", allow_headers: :all
  end

  scope "/", StacksWeb do
    pipe_through :browser
    get "/", PageController, :home
    get "/articles", PageController, :articles
    get "/videos", PageController, :videos
    get "/archives", PageController, :archives
    live "/items/:id", ItemLive
  end

  scope "/api", StacksWeb do
    pipe_through :api
    resources "/articles", ArticleController, except: [:edit]
    resources "/videos", VideoController, except: [:edit]

    resources "/items", ItemController, except: [:edit] do
      post "/archive", ItemController, :archive
      post "/unarchive", ItemController, :unarchive
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:stacks, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: StacksWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    scope "/" do
      pipe_through :browser

      oban_dashboard("/oban")
    end
  end
end
