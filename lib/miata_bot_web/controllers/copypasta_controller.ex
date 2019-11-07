defmodule MiataBotWeb.CopyPastaController do
  use MiataBotWeb, :controller
  require Logger

  def index(conn, _params) do
    paste = PastebinRandomizer.good_paste()
    copypasta = PastebinRandomizer.get(paste)
    send_resp(conn, 200, copypasta)
  end
end
