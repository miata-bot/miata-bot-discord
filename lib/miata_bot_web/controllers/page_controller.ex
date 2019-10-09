defmodule MiataBotWeb.PageController do
  use MiataBotWeb, :controller

  def index(conn, _params) do
    auth_url = Application.get_env(:miata_bot, __MODULE__)[:auth_url]
    render(conn, "index.html", auth_url: auth_url)
  end
end
