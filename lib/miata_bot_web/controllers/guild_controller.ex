defmodule MiataBotWeb.GuildController do
  use MiataBotWeb, :controller
  require Logger

  def index(conn, _params) do
    access_token = get_session(conn, "discord_token")["access_token"] || raise("no token")
    guilds = MiataBot.Discord.OAuth2.get_guilds!(access_token)
    render(conn, "index.html", guilds: guilds)
  end

  def show(conn, %{"id" => guild_id}) do
    {:ok, guild_id} = MiataBot.Snowflake.cast(guild_id)
    guild = Nostrum.Api.get_guild!(guild_id)
    render(conn, "show.html", guild: guild)
  end
end
