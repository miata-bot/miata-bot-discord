defmodule MiataBotWeb.PageController do
  use MiataBotWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
