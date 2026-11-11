defmodule PortfolioHermannWeb.Router do
  use PortfolioHermannWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PortfolioHermannWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PortfolioHermannWeb do
    pipe_through :browser

    live_session :default,
      on_mount: [PortfolioHermannWeb.Hooks.Analytics] do
      live "/", HomeLive
      live "/about", AboutLive
      live "/projects", ProjectsLive
      live "/projects/:id", ProjectsLive
      live "/contact", ContactLive
      live "/contact/merci", ContactThanksLive
      live "/blog", BlogLive
      live "/blog/:slug", BlogLive
      get "/health", HealthController, :index
      get "/uploads/:filename", UploadController, :show
      get "/article-media/:filename", ArticleMediaController, :show
    end
  end

  scope "/api", PortfolioHermannWeb do
    pipe_through :api

    post "/articles", ArticleApiController, :upsert
    delete "/articles/:slug", ArticleApiController, :delete
    post "/articles/media", ArticleMediaController, :create
  end

  scope "/admin", PortfolioHermannWeb do
    pipe_through :browser

    live_session :admin,
      on_mount: [PortfolioHermannWeb.AdminAuth] do
      live "/projects", AdminProjectsLive
      live "/experiences", AdminExperiencesLive
      live "/articles", AdminArticlesLive
      live "/stats", AdminStatsLive
    end

    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", PortfolioHermannWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:portfolio_hermann, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PortfolioHermannWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
