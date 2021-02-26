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

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :mail do
    plug :accepts, ["html", "json"]
  end

  scope "/", MiataBotWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/", MiataBotWeb do
    pipe_through :mail
    post "/mail", MailController, :mail
  end

  # Other scopes may use custom stacks.
  # scope "/api", MiataBotWeb do
  #   pipe_through :api
  # end
end
