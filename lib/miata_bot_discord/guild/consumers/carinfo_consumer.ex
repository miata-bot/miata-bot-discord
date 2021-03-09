defmodule MiataBotDiscord.Guild.CarinfoConsumer do
  @moduledoc """
  Processes commands from users
  """

  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.{EventDispatcher, Responder}
  alias MiataBotDiscord.GuildCache

  alias Nostrum.Struct.{Message, Embed}

  @help_message %Embed{}
                |> Embed.put_title("Available commands")
                |> Embed.put_field("carinfo", """
                Shows the author's carinfo
                """)
                |> Embed.put_field("carinfo me", """
                Shows *your* carinfo
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
                |> Embed.put_field("carinfo update wheels <wheel name>", """
                Sets the author's carinfo wheels
                """)
                |> Embed.put_field("carinfo update tires <tire name>", """
                Sets the author's carinfo tire
                """)
                |> Embed.put_field("carinfo update instagram <handle>", """
                Sets the author's instagram handle
                """)

  @doc false
  def start_link({guild, config, current_user}) do
    GenStage.start_link(__MODULE__, {guild, config, current_user}, name: via(guild, __MODULE__))
  end

  @impl GenStage
  def init({guild, config, current_user}) do
    {:producer_consumer, %{guild: guild, current_user: current_user, config: config},
     subscribe_to: [via(guild, EventDispatcher)]}
  end

  @impl GenStage
  def handle_events(events, _from, %{current_user: %{id: current_user_id}} = state) do
    {actions, state} =
      Enum.reduce(events, {[], state}, fn
        # Ignore messages from self
        {:MESSAGE_CREATE, %{author: %{id: author_id}}}, {actions, state}
        when author_id == current_user_id ->
          {actions, state}

        {:MESSAGE_CREATE, message}, {actions, state} ->
          handle_message(message, {actions, state})

        _, {actions, state} ->
          {actions, state}
      end)

    {:noreply, actions, state}
  end

  # this blocks all other patterns from matching in the verification channel. IDK what to do about it
  # def handle_message(%Message{channel_id: verification_channel_id} = message, {actions, %{config: %{verification_channel_id: verification_channel_id}} = state}) do
  #   case message.attachments do
  #     [%{url: url} | _rest] ->
  #       year = extract_year(message.content)
  #       params = %{image_url: url, discord_user_id: message.author.id, year: year}
  #       do_update(verification_channel_id, message.author, params, {actions, state})

  #     _ ->
  #       {actions, state}
  #   end
  # end

  def handle_message(%Message{channel_id: channel_id, content: "$carinfo help"}, {actions, state}) do
    {actions ++ [{:create_message!, [channel_id, [embed: @help_message]]}], state}
  end

  def handle_message(%Message{channel_id: channel_id, content: "$carinfo"}, {actions, state}) do
    {actions ++ [{:create_message!, [channel_id, [embed: @help_message]]}], state}
  end

  def handle_message(
        %Message{channel_id: channel_id, author: author, content: "$carinfo me" <> _},
        {actions, state}
      ) do
    embed = carinfo(author)
    {actions ++ [{:create_message!, [channel_id, [embed: embed]]}], state}
  end

  def handle_message(
        %Message{channel_id: channel_id, content: "$carinfo get" <> user} = message,
        {actions, state}
      ) do
    case get_user(message) do
      {:ok, user} ->
        embed = carinfo(user)
        {actions ++ [{:create_message!, [channel_id, [embed: embed]]}], state}

      {:error, _} ->
        {actions ++ [{:create_message!, [channel_id, "Could not find user: #{user}"]}], state}
    end
  end

  def handle_message(
        %Message{
          content: "$carinfo update image" <> _,
          channel_id: channel_id,
          author: author,
          attachments: [attachment | _]
        },
        {actions, state}
      ) do
    params = %{image_url: attachment.url, discord_user_id: author.id}
    do_update_image(channel_id, author, params, {actions, state})
  end

  def handle_message(
        %Message{
          content: "$carinfo update year " <> year,
          channel_id: channel_id,
          author: author
        },
        {actions, state}
      ) do
    params = %{year: year, discord_user_id: author.id}
    do_update(channel_id, author, params, {actions, state})
  end

  def handle_message(
        %Message{
          content: "$carinfo update color code " <> color,
          channel_id: channel_id,
          author: author
        },
        {actions, state}
      ) do
    params = %{color: color, discord_user_id: author.id}
    do_update(channel_id, author, params, {actions, state})
  end

  def handle_message(
        %Message{
          content: "$carinfo update title " <> title,
          channel_id: channel_id,
          author: author
        },
        {actions, state}
      ) do
    params = %{description: title, discord_user_id: author.id}
    do_update(channel_id, author, params, {actions, state})
  end

  def handle_message(
        %Message{
          content: "$carinfo update description " <> description,
          channel_id: channel_id,
          author: author
        },
        {actions, state}
      ) do
    params = %{description: description, discord_user_id: author.id}
    do_update(channel_id, author, params, {actions, state})
  end

  def handle_message(
        %Message{
          content: "$carinfo update wheels " <> wheels,
          channel_id: channel_id,
          author: author
        },
        {actions, state}
      ) do
    params = %{wheels: wheels, discord_user_id: author.id}
    do_update(channel_id, author, params, {actions, state})
  end

  def handle_message(
        %Message{
          content: "$carinfo update tires " <> tires,
          channel_id: channel_id,
          author: author
        },
        {actions, state}
      ) do
    params = %{tires: tires, discord_user_id: author.id}
    do_update(channel_id, author, params, {actions, state})
  end

  def handle_message(
        %Message{
          content: "$carinfo update instagram " <> instagram_handle,
          channel_id: channel_id,
          author: author
        },
        {actions, state}
      ) do
    params = %{instagram_handle: instagram_handle, discord_user_id: author.id}
    do_update_user(channel_id, author, params, {actions, state})
  end

  def handle_message(_message, {actions, state}) do
    {actions, state}
  end

  def do_update_user(channel_id, author, params, {actions, state}) do
    case MiataBot.Partpicker.update_user(author.id, params) do
      {:ok, _user} ->
        embed = carinfo(author)
        {actions ++ [{:create_message!, [channel_id, [embed: embed]]}], state}

      {:error, reason} ->
        embed =
          %Embed{}
          |> Embed.put_title("Error updating info")
          |> Embed.put_color(0xFF0000)
          |> put_errors(reason)

        {actions ++ [{:create_message!, [channel_id, [embed: embed]]}], state}
    end
  end

  def do_update_image(channel_id, _author, _params, {actions, state}) do
    {actions ++
       [
         {:create_message!,
          [
            channel_id,
            "that doesn't work right now sorry. you can do that on the website: https://miatapartpicker.gay"
          ]}
       ], state}
  end

  def do_update(channel_id, author, params, {actions, state}) do
    with [info | _] <- MiataBot.Partpicker.builds(author.id),
         {:ok, info} <- MiataBot.Partpicker.update_build(author.id, info.uid, params),
         embed <- embed_from_info(author, info) do
      {actions ++ [{:create_message!, [channel_id, [embed: embed]]}], state}
    else
      [] ->
        embed =
          %Embed{}
          |> Embed.put_title("#{author.username}'s Miata")
          |> Embed.put_description("#{author.username} has not registered a vehicle.")

        {actions ++ [{:create_message!, [channel_id, [embed: embed]]}], state}

      {:error, reason} ->
        embed =
          %Embed{}
          |> Embed.put_title("Error updating info")
          |> Embed.put_color(0xFF0000)
          |> put_errors(reason)

        {actions ++ [{:create_message!, [channel_id, [embed: embed]]}], state}
    end
  end

  def put_errors(embed, error) do
    Enum.reduce(error, embed, fn {key, msg}, embed ->
      Embed.put_field(embed, to_string(key), Enum.join(msg, " "))
    end)
  end

  def carinfo(author) do
    case MiataBot.Partpicker.builds(author.id) do
      [] ->
        %Embed{}
        |> Embed.put_title("#{author.username}'s Miata")
        |> Embed.put_url("https://miatapartpicker.gay/builds/new")
        |> Embed.put_description(
          "#{author.username} has not registered a vehicle. Visit the link to create one"
        )

      [info | _] ->
        embed_from_info(author, info)
    end
  end

  def embed_from_info(author, info) do
    %Embed{}
    |> Embed.put_title("#{author.username}'s Miata")
    |> Embed.put_color(0xD11A06)
    |> Embed.put_field("Year", info.year || "unknown year")
    |> Embed.put_field("Color Code", info.color || "unknown color code")
    |> Embed.put_description(info.description)
    |> Embed.put_url("https://miatapartpicker.gay/car/#{info.uid}")
    |> maybe_add_image(info)
    |> maybe_add_wheels(info)
    |> maybe_add_tires(info)
    |> maybe_add_instagram(info)
  end

  def maybe_add_image(embed, %{banner_photo_url: nil}), do: embed
  def maybe_add_image(embed, %{banner_photo_url: url}), do: Embed.put_image(embed, url)

  def maybe_add_wheels(embed, %{wheels: nil}), do: embed
  def maybe_add_wheels(embed, %{wheels: wheels}), do: Embed.put_field(embed, "Wheels", wheels)

  def maybe_add_tires(embed, %{tires: nil}), do: embed
  def maybe_add_tires(embed, %{tires: tires}), do: Embed.put_field(embed, "Tires", tires)

  def maybe_add_instagram(embed, %{user: %{instagram_handle: nil}}), do: embed

  def maybe_add_instagram(embed, %{user: %{instagram_handle: "@" <> handle}}),
    do: Embed.put_field(embed, "Instagram", "https://instagram.com/#{handle}")

  defp get_user(%Message{mentions: [user | _]}) do
    {:ok, user}
  end

  defp get_user(%Message{content: "$carinfo get" <> identifier} = message) do
    case String.trim(identifier) do
      "me" ->
        {:ok, message.author}

      "" ->
        {:ok, message.author}

      str ->
        case Snowflake.cast(str) do
          {:ok, snowflake} ->
            Logger.info("using snowflake: #{str}")
            Responder.execute_action(message.guild_id, {:get_user, [snowflake]})

          :error ->
            Logger.info("using nick: #{str}")
            get_user_by_nick(str, message)
        end
    end
  end

  defp get_user_by_nick(nick, %Message{guild_id: guild_id} = _message) do
    Logger.info("looking up by nick: #{nick}")

    maybe_member =
      Enum.find(GuildCache.list_guild_members(guild_id), fn
        {_id, %Nostrum.Struct.Guild.Member{nick: ^nick}} ->
          true

        {_id, %Nostrum.Struct.Guild.Member{user: %{username: ^nick}}} ->
          true

        {_id, %Nostrum.Struct.Guild.Member{} = _member} ->
          # Logger.info("not match: #{inspect(member)}")
          false
      end)

    case maybe_member do
      {id, _member} ->
        Responder.execute_action(guild_id, {:get_user, [id]})

      nil ->
        {:error, "unable to match: #{nick}"}
    end
  end
end
