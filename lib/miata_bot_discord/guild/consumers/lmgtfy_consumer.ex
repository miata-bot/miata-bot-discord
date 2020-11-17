def handle_event(
  {:MESSAGE_CREATE, %{content: "!google " <> search, channel_id: channel_id}, _state}
) do
q = URI.encode_query(%{q: search, iee: 1})
lmgtfy = "https://lmgtfy.com/?#{q}"

embed =
Embed.put_url(%Embed{}, lmgtfy)
|> Embed.put_title("let me google that for you")

Api.create_message!(channel_id, embed: embed)
end
