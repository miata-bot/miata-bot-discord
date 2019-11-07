defmodule MiataBotWeb.Router do
  use MiataBotWeb, :router
  require Logger

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :discord_oauth2 do
    plug :ensure_discord_auth
  end

  def ensure_discord_auth(conn, _opts) do
    if is_nil(get_session(conn, "discord_token")) do
      send_resp(conn, 401, "not authenticated by discord!")
    else
      conn
    end
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MiataBotWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/auth/callback", AuthCallbackController, :index
    get "/copypasta", CopyPastaController, :index
  end

  scope "/", MiataBotWeb do
    pipe_through [:browser, :discord_oauth2]
    resources "/guilds", GuildController, only: [:index, :show]
  end

  # Other scopes may use custom stacks.
  # scope "/api", MiataBotWeb do
  #   pipe_through :api
  # end
end
