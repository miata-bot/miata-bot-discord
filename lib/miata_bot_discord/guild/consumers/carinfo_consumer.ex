def handle_event({:MESSAGE_CREATE, %{channel_id: @verification_channel_id} = message, _state}) do
  case message.attachments do
    [%{url: url} | _rest] ->
      year = extract_year(message.content)
      params = %{image_url: url, discord_user_id: message.author.id, year: year}
      do_update(@verification_channel_id, message.author, params)

    _ ->
      :noop
  end
end

def do_update(channel_id, author, params) do
  info = Repo.get_by(Carinfo, discord_user_id: author.id) || %Carinfo{}
  changeset = Carinfo.changeset(info, params)

  embed =
    case Repo.insert_or_update(changeset) do
      {:ok, _} ->
        carinfo(author)

      {:error, changeset} ->
        changeset_to_error_embed(changeset)
    end

  Api.create_message(channel_id, embed: embed)
end

def changeset_to_error_embed(changeset) do
  embed = Embed.put_title(%Embed{}, "Error performing action #{changeset.action}")

  Enum.reduce(changeset.errors, embed, fn {key, {msg, _opts}}, embed ->
    Embed.put_field(embed, to_string(key), msg)
  end)
end

def carinfo(author) do
  case Repo.get_by(Carinfo, discord_user_id: author.id) do
    nil ->
      %Embed{}
      |> Embed.put_title("#{author.username}'s Miata")
      |> Embed.put_description("#{author.username} has not registered a vehicle.")

    %Carinfo{} = info ->
      %Embed{}
      |> Embed.put_title(info.title || "#{author.username}'s Miata")
      |> Embed.put_color(info.color || 0xD11A06)
      |> Embed.put_field("Year", info.year || "unknown year")
      |> Embed.put_field("Color Code", info.color_code || "unknown color code")
      |> Embed.put_image(info.image_url)
  end
end

defp extract_year(_), do: nil

defp get_user(%{mentions: [user | _]}) do
  {:ok, user}
end

defp get_user(%{content: "$carinfo get" <> identifier} = message) do
  case String.trim(identifier) do
    "me" ->
      {:ok, message.author}

    "" ->
      {:ok, message.author}

    str ->
      case Nostrum.Snowflake.cast(str) do
        {:ok, snowflake} ->
          Logger.info("using snowflake: #{str}")
          Api.get_user(snowflake)

        :error ->
          Logger.info("using nick: #{str}")
          get_user_by_nick(str, message)
      end
  end
end

defp get_user_by_nick(nick, %{guild_id: guild_id} = _message) do
  Logger.info("looking up by nick: #{nick}")

  maybe_member =
    Enum.find(GuildCache.list_guild_members(guild_id), fn
      {_id, %{nick: ^nick}} ->
        true

      {_id, %{user: %{username: ^nick}}} ->
        true

      {_id, _member} ->
        # Logger.info "not match: #{inspect(member)}"
        false
    end)

  case maybe_member do
    {id, _member} -> Api.get_user(id)
    nil -> {:error, "unable to match: #{nick}"}
  end
end

def handle_command("carinfo help", %{channel_id: channel_id}) do
  Api.create_message(channel_id, embed: @help_message)
end

def handle_command("carinfo", %{channel_id: channel_id}) do
  Api.create_message(channel_id, embed: @help_message)
end

def handle_command("carinfo me" <> _, %{channel_id: channel_id, author: author}) do
  embed = carinfo(author)
  Api.create_message(channel_id, embed: embed)
end

def handle_command("carinfo get" <> user, %{channel_id: channel_id} = message) do
  Logger.info("message=#{inspect(message)}")

  case get_user(message) do
    {:ok, user} ->
      embed = carinfo(user)
      Api.create_message(channel_id, embed: embed)

    {:error, _} ->
      Api.create_message(channel_id, "Could not find user: #{user}")
  end
end

def handle_command("carinfo update image" <> _, %{
      channel_id: channel_id,
      author: author,
      attachments: [attachment | _]
    }) do
  params = %{image_url: attachment.url, discord_user_id: author.id}
  do_update(channel_id, author, params)
end

def handle_command("carinfo update year " <> year, %{
      channel_id: channel_id,
      author: author
    }) do
  params = %{year: year, discord_user_id: author.id}
  do_update(channel_id, author, params)
end

def handle_command("carinfo update color code " <> color_code, %{
      channel_id: channel_id,
      author: author
    }) do
  params = %{color_code: color_code, discord_user_id: author.id}
  do_update(channel_id, author, params)
end

def handle_command("carinfo update title " <> title, %{
      channel_id: channel_id,
      author: author
    }) do
  params = %{title: title, discord_user_id: author.id}
  do_update(channel_id, author, params)
end
