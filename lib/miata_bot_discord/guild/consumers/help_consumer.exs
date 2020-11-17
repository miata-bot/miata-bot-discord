@help_message %Embed{}
              |> Embed.put_title("Available commands")
              |> Embed.put_field("carinfo", """
              Shows the author's carinfo
              """)
              |> Embed.put_field("carinfo get <user>", """
              Shows a users carinfo
              """)
              |> Embed.put_field("carinfo update title", """
              Sets the author's carinfo title
              """)
              |> Embed.put_field("carinfo update image", """
              Updates the author's carinfo from an attached photo
              """)
              |> Embed.put_field("carinfo update year <year>", """
              Sets the author's carinfo year
              """)
              |> Embed.put_field("carinfo update color code <color>", """
              Sets the author's carinfo color code
              """)

def handle_command("help", %{channel_id: channel_id}) do
  Api.create_message(channel_id, embed: @help_message)
end
