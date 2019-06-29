defmodule MiataBot do
  def qr(channel_id, user_id, message) do
    url = Application.get_all_env(:miata_bot)[MiataBot.Web.Endpoint][:url]
    message = URI.encode_www_form(message)
    url = url <> "/qr?channel_id=#{channel_id}&user_id=#{user_id}&message=#{message}"
    {:ok, qr} = QRCode.create(url)
    {:ok, _} = QRCode.Svg.save_as(qr, "/tmp/qr.svg")

    Mogrify.open("/tmp/qr.svg")
    |> Mogrify.format("png")
    |> Mogrify.save(path: "/tmp/qr.png")

    Nostrum.Api.create_message!(351_767_273_712_910_336, file: "/tmp/qr.png")
  end
end
