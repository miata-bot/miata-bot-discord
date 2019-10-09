defmodule MiataBot.Web.Router do
  use Plug.Router
  require Logger

  plug(:match)
  plug(:fetch_query_params)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "hello, world")
  end

  get "/dashboard/:guild_id" do
    send_resp(conn, 200, eval_template("dashboard.html.eex"))
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  def eval_template(file, bindings \\ []) do
    file = Application.app_dir(:miata_bot, ["priv", "templates", file])
    EEx.eval_file(file, bindings)
  end
end
