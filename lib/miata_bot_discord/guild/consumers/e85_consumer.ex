@e85_help_message %Embed{}
|> Embed.put_title("Available E85 commands")
|> Embed.put_field("e85 zip <zip>", """
Shows e85 stations in a zip
""")
|> Embed.put_field("e85 state <state code>", """
Shows e85 stations in a state
""")

def handle_command("e85 state " <> state_code, %{channel_id: channel_id}) do
  state_code = String.upcase(state_code)

  case Nrel.e85_stations_by_state(state_code, %{limit: 5}) do
    {:ok, stations} ->
      embed = e85_stations_to_embed(stations)
      Api.create_message!(channel_id, embed: embed)

    _ ->
      Api.create_message!(channel_id, "developer.nrel.gov is currently unavailable")
  end
end

def handle_command("e85 zip " <> zip_code, %{channel_id: channel_id}) do
  case Nrel.e85_stations_by_zip(zip_code, %{limit: 5}) do
    {:ok, stations} ->
      embed = e85_stations_to_embed(stations)
      Api.create_message!(channel_id, embed: embed)

    _ ->
      Api.create_message!(channel_id, "developer.nrel.gov is currently unavailable")
  end
end

def handle_command("e85" <> _, %{channel_id: channel_id}) do
  Api.create_message!(channel_id, embed: @e85_help_message)
end
