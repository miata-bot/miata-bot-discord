defmodule MiataBotWeb.GuildController do
  use MiataBotWeb, :controller
  require Logger

  def index(conn, _params) do
    access_token = get_session(conn, "discord_token")["access_token"] || raise("no token")
    guilds = MiataBot.Discord.OAuth2.get_guilds!(access_token)
    render(conn, "index.html", guilds: guilds)
  end
end
