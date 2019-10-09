defmodule MiataBot.Web.Router do
  alias MiataBot.GuildCache
  use Plug.Router
  require Logger

  plug(:match)
  plug(:fetch_query_params)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "hello, world")
  end

  get "/dashboard" do
    guilds = GuildCache.list_guilds()
    send_resp(conn, 200, eval_template("dashboard#index.html.eex", guilds: guilds))
  end

  get "/dashboard/:guild_id" do
    case GuildCache.get_guild(guild_id) do
      nil ->
        send_resp(conn, 404, "could not find guild: #{guild_id}")

      guild ->
        send_resp(conn, 200, eval_template("dashboard#show.html.eex", guild: guild))
    end
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  def eval_template(file, bindings \\ []) do
    file = Application.app_dir(:miata_bot, ["priv", "templates", file])
    EEx.eval_file(file, bindings)
  end
end
