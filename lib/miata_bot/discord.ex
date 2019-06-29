defmodule MiataBot.Discord do
  alias MiataBot.{
    Repo,
    Carinfo,
    LookingForMiataTimer
  }

  import MiataBot.Discord.Util

  require Logger

  use Nostrum.Consumer
  alias Nostrum.Api
  alias Nostrum.Struct.Embed

  # @miata_discord_guild_id 322_080_266_761_797_633
  # 322080266761797633
  @verification_channel_id 322_127_502_212_333_570
  @looking_for_miata_role_id 504_088_951_485_890_561
  # @miata_fan_role_id 439_493_557_301_280_789
  @maysh_user_id 326_204_806_165_430_273

  Module.register_attribute(__MODULE__, :bangs, accumulate: true)

  def start_link do
    Consumer.start_link(__MODULE__, name: __MODULE__)
  end

  # uncomment to own Mark Sticken
  # def handle_event({:MESSAGE_CREATE, {%{author: %{id: 362309360124428299}, channel_id: channel_id} = message}, _state}) do
  #   Api.create_message(channel_id, "<@!362309360124428299> https://media.discordapp.net/attachments/322162421156282369/581557012593246209/13t5kz.jpg")
  #   Api.delete_message(message)
  # end

  # Uncomment to own Dey See Me Corollin
  # @dey_see_me_corollin_user_id 234_361_846_092_660_738
  # @general_miata_channel_id 322_080_266_761_797_633
  # def handle_event(
  #       {:MESSAGE_CREATE,
  #        {%{author: %{id: @dey_see_me_corollin_user_id}, channel_id: @general_miata_channel_id} =
  #           message}, _state}
  #     ) do
  #   Api.create_message(@general_miata_channel_id, "<@!#{@dey_see_me_corollin_user_id}> denied")
  #   Api.delete_message(message)
  # end

  bang "ya rip", "https://www.youtube.com/watch?v=fKLmZNnMT0A"
  bang "yeah rip", "https://www.youtube.com/watch?v=fKLmZNnMT0A"

  bang "!rotaryroast", "https://www.stancenation.com/wp-content/uploads/2012/04/1211.jpg"

  bang "!monstertruck",
       "https://cdn.discordapp.com/attachments/500143495043088395/590656753583259658/20190610_170551_HDR.jpg"

  bang "!hercroast",
       "https://cdn.discordapp.com/attachments/500143495043088395/590654628115382277/032216_Fire_Car_AB.jpg"

  bang "!longintake",
       "https://cdn.discordapp.com/attachments/384483113985900544/592810948201545739/IMG_20190613_153900.jpg"

  bang "!18swapintake",
       "https://media.discordapp.net/attachments/322080529245798401/593511885664550921/IMG_1140.jpg"

  bang "!torquespecs",
       "https://www.miata.net/garage/torque.html"

  bang "!fartbeard",
       "https://cdn.discordapp.com/attachments/322162421156282369/593854324891713546/image0.jpg"

  bang "!chicagoroast", "<@!#{@maysh_user_id}> Chicago sux lmao"

  bang "!bmwroast",
       "https://media.discordapp.net/attachments/322162421156282369/593869644365037628/b49d82b0ad.png?width=590&height=658"

  bang "!e", "https://i.ytimg.com/vi/J6NioWmscDc/maxresdefault.jpg"

  bang "!flroast",
       "https://cdn.discordapp.com/attachments/322162421156282369/593905029094572032/florida.gif"

  bang "!floridiaroast",
       "https://cdn.discordapp.com/attachments/322162421156282369/593905029094572032/florida.gif"

  bang "!boing",
       "https://www.youtube.com/watch?v=hoS1MCF8AeI"

  bang "!weed",
       "https://www.youtube.com/watch?v=5lEelz0iUJo"

  bang "!doot",
       "https://youtu.be/eVrYbKBrI7o"

  bang "!nou",
       "https://cdn.discordapp.com/attachments/351767273712910336/594569216640942083/GJElD4jJUQ2xAPwjRIjBcUeAf311aN1oa791xzRpQbVJx1oF-zjoQZ1Sq1R_JpV31jSBPOJ9WvIQvhFDVpp7Cwoaye4yR0VxEOsy.png"

  bang "!rotary",
       "https://www.youtube.com/watch?v=FZUcpVmEHuk"

  bang "!fca",
       "https://www.youtube.com/watch?v=FZUcpVmEHuk"

  bang "!FCA",
       "https://www.youtube.com/watch?v=FZUcpVmEHuk"

  bang "!potato",
       "https://cdn.discordapp.com/attachments/591751583767724042/594582309639028745/unknown.png"

  bang "!playstation",
       "https://youtu.be/oAhvQoLpvsM"

  def handle_event({:MESSAGE_CREATE, {%{content: <<"!qr", content::binary>>} = message}, _state}) do
    Logger.info("#{inspect(message, limit: :infinity)}")
  end

  def handle_event({:MESSAGE_CREATE, {%{content: "$" <> command} = message}, _state}) do
    handle_command(command, message)
  end

  def handle_event({:MESSAGE_CREATE, {%{channel_id: @verification_channel_id} = message}, _state}) do
    case message.attachments do
      [%{url: url} | _rest] ->
        year = extract_year(message.content)
        params = %{image_url: url, discord_user_id: message.author.id, year: year}
        do_update(@verification_channel_id, message.author, params)

      _ ->
        :noop
    end
  end

  def handle_event({:GUILD_AVAILABLE, {data}, _ws_state}) do
    Logger.info("GUILD AVAILABLE: #{inspect(data, limit: :infinity)}")
    table_name = String.to_atom(to_string(data.id))

    case :ets.whereis(table_name) do
      :undefined ->
        Logger.warn("Creating new table: #{inspect(table_name)}")
        ^table_name = :ets.new(table_name, [:named_table, :ordered_set, :protected])

      ref when is_reference(ref) ->
        Logger.warn("Table already created: #{inspect(table_name)}")
        table_name
    end

    for {member_id, m} <- data.members do
      Logger.info "inserting user: #{member_id}"
      true = :ets.insert(table_name, {member_id, m})

      if @looking_for_miata_role_id in m.roles do
        ensure_looking_for_miata_timer(m)
      end
    end
  end

  def handle_event({:GUILD_MEMBER_UPDATE, {_member_id, old, new}, _ws_state}) do
    if @looking_for_miata_role_id in (new.roles -- old.roles) do
      Logger.info("refreshing timer for #{new.user.username}")
      timer = ensure_looking_for_miata_timer(new)
      refresh_looking_for_miata_timer(timer)
    end

    if @looking_for_miata_role_id in (old.roles -- new.roles) do
      Logger.info("refreshing timer for #{new.user.username}")
      timer = ensure_looking_for_miata_timer(new)
      Repo.delete!(timer)
    end
  end

  def handle_event(event) do
    _ = inspect(event)
    # IO.inspect(event, label: "UNHANDLED EVENT")
    :noop
  end

  defp ensure_looking_for_miata_timer(member) do
    case Repo.get_by(LookingForMiataTimer, discord_user_id: member.user.id) do
      nil ->
        LookingForMiataTimer.changeset(%LookingForMiataTimer{}, %{
          joined_at: member.joined_at,
          discord_user_id: member.user.id
        })
        |> Repo.insert!()

      timer ->
        timer
    end
  end

  def refresh_looking_for_miata_timer(timer) do
    LookingForMiataTimer.changeset(timer, %{
      refreshed_at: DateTime.utc_now()
    })
    |> Repo.update!()
  end

  def handle_command("bangs", %{channel_id: channel_id}) do
    msg = Enum.join(@bangs, "\n")
    Api.create_message!(channel_id, "Available bangs: #{msg}")
  end

  def handle_command("help", %{channel_id: channel_id}) do
    embed =
      %Embed{}
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

    Api.create_message(channel_id, embed: embed)
  end

  def handle_command("carinfo", %{channel_id: channel_id, author: author}) do
    embed = carinfo(author)
    Api.create_message(channel_id, embed: embed)
  end

  def handle_command("carinfo get" <> user, %{channel_id: channel_id}) do
    case get_user(user) do
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

  def handle_command(_command, message) do
    IO.inspect(message, label: "unhandled command")
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

  defp get_user("<@!" <> almost_snowflake) do
    snowflake = String.trim_trailing(almost_snowflake, ">")
    get_user(snowflake)
  end

  defp get_user(user) do
    case Nostrum.Snowflake.cast(user) do
      {:ok, snowflake} ->
        Api.get_user(snowflake)

      _ ->
        {:error, "unknown user"}
    end
  end
end
