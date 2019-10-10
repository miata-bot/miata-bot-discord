defmodule MiataBotWeb.AuthCallbackController do
  use MiataBotWeb, :controller
  require Logger
  alias MiataBot.Discord.OAuth2
  @admin_ids ["316741621498511363", "184447193996984321"]

  def index(conn, %{"code" => code}) do
    discord_token = OAuth2.get_token!(code, "identify email connections guilds")

    case OAuth2.get_userdata!(discord_token["access_token"]) do
      %{"email" => _email, "id" => discord_user_id} = userdata
      when discord_user_id in @admin_ids ->
        conn
        |> put_session("discord_userdata", userdata)
        |> put_session("discord_token", discord_token)
        |> put_resp_header("location", "/guilds")
        |> send_resp(301, "/guilds")

      %{"email" => _email, "id" => discord_user_id} ->
        conn
        |> put_session("discord_userdata", nil)
        |> put_session("discord_token", nil)
        |> send_resp(401, "user is not an admin: #{inspect(discord_user_id)}")

      error ->
        conn
        |> put_session("discord_userdata", nil)
        |> put_session("discord_token", nil)
        |> send_resp(401, "could not grant authorization: #{inspect(error)}")
    end
  end
end
