defmodule MiataBot.Web.Router do
  use Plug.Router
  require Logger

  plug(:match)
  plug(:fetch_query_params)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "hello, world")
  end

  get "/qr" do
    Logger.info("#{inspect(conn.params)}")
    channel_id = conn.params["channel_id"]
    channel_id = Nostrum.Snowflake.cast!(channel_id)
    user_id = conn.params["user_id"]
    user_id = Nostrum.Snowflake.cast!(user_id)

    message = conn.params["message"]
    Nostrum.Api.create_message!(channel_id, "<@!#{user_id}> #{message}")

    send_resp(conn, 200, """
    <html>
    <head>
    </head>
    <body>
    good job
    <script type="text/javascript">
    window.onload = function() {
      window.close();
    }
    </script>
    </body>
    </html>
    """)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
