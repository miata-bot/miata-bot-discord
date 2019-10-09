defmodule MiataBotWeb.AuthCallbackController do
  use MiataBotWeb, :controller
  require Logger
  alias MiataBot.Discord.OAuth2

  def index(conn, %{"code" => code}) do
    discord_token = OAuth2.get_token!(code, "identify email connections guilds")

    case OAuth2.get_userdata!(discord_token["access_token"]) do
      %{"email" => _email, "id" => _discord_user_id} = userdata ->
        conn
        |> put_session("discord_userdata", userdata)
        |> put_session("discord_token", discord_token)
        |> send_resp(200, Jason.encode!(userdata, pretty: true))

      error ->
        conn
        |> put_session("discord_userdata", nil)
        |> send_resp(401, "could not grant authorization: #{inspect(error)}")
    end
  end
end
