defmodule MiataBot.Web.Router do
  use Plug.Router
  require Logger

  plug(:match)
  plug(:fetch_query_params)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "hello, world")
  end

  get "/qr/:id" do
    Logger.info("#{inspect(conn.params)}")
    qr = MiataBot.Repo.get_by(MiataBot.QRCode, id: id)
    Nostrum.Api.create_message(qr.discord_channel_id, "<@!#{qr.discord_user_id}> #{qr.message}")

    resp =
      Poison.encode!(%{
        discord_guild_id: qr.discord_guild_id,
        discord_channel_id: qr.discord_channel_id,
        discord_user_id: qr.discord_user_id,
        inserted_at: qr.inserted_at,
        updated_at: qr.updated_at
      })

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, resp)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
