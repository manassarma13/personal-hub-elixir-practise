defmodule PersonalHubWeb.Router do
  use PersonalHubWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PersonalHubWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", PersonalHubWeb do
    pipe_through :browser

    # Dashboard
    live "/", DashboardLive, :index

    # Kanban Board + Calendar
    live "/kanban", KanbanLive.Index, :index

    # Blog Posts
    live "/posts", PostLive.Index, :index
    live "/posts/new", PostLive.Index, :new
    live "/posts/:id/edit", PostLive.Index, :edit
    live "/posts/:id", PostLive.Show, :show

    # Notes
    live "/notes", NoteLive.Index, :index
    live "/notes/new", NoteLive.Index, :new
    live "/notes/:id/edit", NoteLive.Index, :edit

    # Tasks
    live "/tasks", TaskLive.Index, :index
    live "/tasks/new", TaskLive.Index, :new
    live "/tasks/:id/edit", TaskLive.Index, :edit

    # Documents
    live "/documents", DocumentLive.Index, :index

    # Data Visualization
    live "/visualize", VisualizeLive.Index, :index

    # Chess
    live "/chess", ChessLive.Index, :index

    # Typing Game
    live "/typing", TypingLive.Index, :index
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:personal_hub_web, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PersonalHubWeb.Telemetry
    end
  end
end
