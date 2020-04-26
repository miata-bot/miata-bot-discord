defmodule MiataBot.Discord do
  alias MiataBot.{
    Repo,
    CopyPastaWorker,
    Carinfo,
    GuildCache,
    LookingForMiataTimer
  }

  import MiataBot.Discord.Util

  require Logger

  use Nostrum.Consumer
  alias Nostrum.Api
  alias Nostrum.Struct.{Embed, User}

  @josh_user_id 149_677_654_101_065_728
  @herc_user_id 226_052_366_745_600_000

  # @miata_discord_guild_id 322_080_266_761_797_633
  # 322080266761797633
  @verification_channel_id 322_127_502_212_333_570
  @looking_for_miata_role_id 504_088_951_485_890_561
  # @miata_fan_role_id 439_493_557_301_280_789
  @maysh_user_id 326_204_806_165_430_273
  # @justin_user_id 126_155_471_886_352_385
  # @easyy_user_id 151_099_008_230_752_256
  @memes_channel_id 555_431_196_884_992_000
  @bot_spam_channel_id 351_767_273_712_910_336
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

  @e85_help_message %Embed{}
                    |> Embed.put_title("Available E85 commands")
                    |> Embed.put_field("e85 zip <zip>", """
                    Shows e85 stations in a zip
                    """)
                    |> Embed.put_field("e85 state <state code>", """
                    Shows e85 stations in a state
                    """)

  Module.register_attribute(__MODULE__, :bangs, accumulate: true)

  def start_link do
    Consumer.start_link(__MODULE__, name: __MODULE__)
  end

  # uncomment to own Mark Sticken
  # def handle_event({:MESSAGE_CREATE, {%{author: %{id: 362309360124428299}, channel_id: channel_id} = message}, _state}) do
  #   Api.create_message(channel_id, "<@!362309360124428299> https://media.discordapp.net/attachments/322162421156282369/581557012593246209/13t5kz.jpg")
  #   Api.delete_message(message)
  # end

  # uncomment to own Syylo#2314
  # def handle_event({:MESSAGE_CREATE, {%{author: %{id: 234461132881002498}, channel_id: channel_id} = message}, _state}) do
  #   Nostrum.Api.modify_guild_member(322_080_266_761_797_633, 234461132881002498, [nick: "annoying shitlord"])
  #   Api.create_message(channel_id, "<@!234461132881002498> stop being an annoying shitlord")
  #   Api.delete_message(message)
  # end

  # uncomment to own Syylo#2314
  # def handle_event({:MESSAGE_CREATE, {%{author: %{id: 611072179991478272}, channel_id: channel_id} = message}, _state}) do
  #   Nostrum.Api.modify_guild_member(322_080_266_761_797_633, 611072179991478272, [nick: "still an annoying shitlord"])
  #   # Api.create_message(channel_id, "<@!611072179991478272> stop being an annoying shitlord")
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

  # def handle_event(
  #       {:MESSAGE_CREATE, {%{author: %{id: @justin_user_id}, channel_id: channel_id} = message},
  #        _state}
  #     ) do
  #   e = %Nostrum.Struct.Emoji{
  #     animated: false,
  #     id: 595_123_456_996_278_273,
  #     managed: false,
  #     name: "blackice",
  #     require_colons: true,
  #     roles: [],
  #     user: nil
  #   }

  #   Api.create_reaction(channel_id, message.id, e)
  # end

  # def handle_event(
  #       {:MESSAGE_CREATE, {%{author: %{id: @easyy_user_id}, channel_id: channel_id} = message},
  #        _state}
  #     ) do
  #   e = %Nostrum.Struct.Emoji{
  #     animated: false,
  #     id: 554_801_155_826_253_850,
  #     managed: false,
  #     name: "Raccy",
  #     require_colons: true,
  #     roles: [],
  #     user: nil
  #   }

  #   Api.create_reaction(channel_id, message.id, e)
  # end

  bang("ya rip", "https://www.youtube.com/watch?v=fKLmZNnMT0A")
  bang("yeah rip", "https://www.youtube.com/watch?v=fKLmZNnMT0A")

  bang("!rotaryroast", "https://www.stancenation.com/wp-content/uploads/2012/04/1211.jpg")

  bang(
    "!monstertruck",
    "https://cdn.discordapp.com/attachments/500143495043088395/590656753583259658/20190610_170551_HDR.jpg"
  )

  bang(
    "!hercroast",
    "https://cdn.discordapp.com/attachments/500143495043088395/590654628115382277/032216_Fire_Car_AB.jpg"
  )

  bang(
    "!longintake",
    "https://cdn.discordapp.com/attachments/384483113985900544/592810948201545739/IMG_20190613_153900.jpg"
  )

  bang(
    "!18swapintake",
    "https://media.discordapp.net/attachments/322080529245798401/593511885664550921/IMG_1140.jpg"
  )

  bang(
    "!torquespecs",
    "https://www.miata.net/garage/torque.html"
  )

  bang(
    "!fartbeard",
    "https://cdn.discordapp.com/attachments/322162421156282369/593854324891713546/image0.jpg"
  )

  bang("!chicagoroast", "<@!#{@maysh_user_id}> Chicago sux lmao")

  bang(
    "!bmwroast",
    "https://media.discordapp.net/attachments/322162421156282369/593869644365037628/b49d82b0ad.png?width=590&height=658"
  )

  bang("!e", "https://i.ytimg.com/vi/J6NioWmscDc/maxresdefault.jpg")

  bang(
    "!flroast",
    "https://cdn.discordapp.com/attachments/322162421156282369/593905029094572032/florida.gif"
  )

  bang(
    "!floridiaroast",
    "https://cdn.discordapp.com/attachments/322162421156282369/593905029094572032/florida.gif"
  )

  bang(
    "!boing",
    "https://www.youtube.com/watch?v=hoS1MCF8AeI"
  )

  bang(
    "!weed",
    "https://www.youtube.com/watch?v=5lEelz0iUJo"
  )

  bang(
    "!doot",
    "https://youtu.be/eVrYbKBrI7o"
  )

  bang(
    "!nou",
    "https://cdn.discordapp.com/attachments/351767273712910336/594569216640942083/GJElD4jJUQ2xAPwjRIjBcUeAf311aN1oa791xzRpQbVJx1oF-zjoQZ1Sq1R_JpV31jSBPOJ9WvIQvhFDVpp7Cwoaye4yR0VxEOsy.png"
  )

  bang(
    "!rotary",
    "https://www.youtube.com/watch?v=FZUcpVmEHuk"
  )

  bang(
    "!fca",
    "https://www.youtube.com/watch?v=FZUcpVmEHuk"
  )

  bang(
    "!FCA",
    "https://www.youtube.com/watch?v=FZUcpVmEHuk"
  )

  bang(
    "!potato",
    "https://cdn.discordapp.com/attachments/591751583767724042/594582309639028745/unknown.png"
  )

  bang(
    "!playstation",
    "https://youtu.be/oAhvQoLpvsM"
  )

  bang(
    "!theresyourproblem",
    "https://i.kym-cdn.com/photos/images/newsfeed/000/228/269/demotivational-posters-theres-your-problem.jpg"
  )

  bang(
    "!spaghetti",
    "https://media.discordapp.net/attachments/322080529245798401/611652555037999124/RZ1AVzfrlMtElpqJQLAYfshvvmll12ED3q9MILYBYDESQeWyXiCLu0-93k76UCBtN9RFGjMaFoNme8whKXqXQXTZMWSeR4F4K8hS.png?width=494&height=659"
  )

  bang(
    "!boogerwelds",
    "https://media.discordapp.net/attachments/500143495043088395/631212983875272754/MvLRsuarIkV9veiMwWjIOT3MMVSIiqAp-mYEYVJtSuXroGeOzp5CVWNZ8TZ8pcG13CiXpjIW823BjyZNL-ABnj4mC_sdNKETxtc9.png?width=494&height=659"
  )

  # {:TYPING_START,
  #  {%{
  #     channel_id: 565_041_170_351_259_648,
  #     guild_id: 322_080_266_761_797_633,
  #     member: %{
  #       deaf: false,
  #       joined_at: "2019-03-22T19:51:45.818452+00:00",
  #       mute: false,
  #       nick: "BotuMann",
  #       premium_since: nil,
  #       roles: [322_082_487_243_112_448, 592_059_821_960_986_624, 416_661_791_750_488_065],
  #       user: %{
  #         avatar: "a68c3f4f25a15f0f2235c6bd73f76806",
  #         discriminator: "3977",
  #         id: 160_078_347_886_526_464,
  #         username: "redbeard"
  #       }
  #     },
  #     timestamp: 1_561_955_046,
  #     user_id: 160_078_347_886_526_464
  #   }}}

  # def handle_event({:TYPING_START, {%{channel_id: channel_id, user_id: 126155471886352385}}, _ws_state}) do
  #   Logger.info "tpye: "
  #   Api.create_message!(channel_id, "<@!126155471886352385> get rekt newb")
  # end

  def handle_event({:MESSAGE_CREATE, %{content: "!josh"} = message, _state}) do
    if AnnoyingPingCache.ping?(message.author.id, @josh_user_id) do
      spam = User.mention(%User{id: @josh_user_id}) <> " auto bad lmao"
      Api.create_message!(message.channel_id, spam)
    else
      spam =
        User.mention(%User{id: message.author.id}) <>
          " Don't be a jerk to the poor boi. he already has an auto miata."

      Api.create_message!(message.channel_id, spam)
    end
  end

  def handle_event({:MESSAGE_CREATE, %{content: "!herc"} = message, _state}) do
    if AnnoyingPingCache.ping?(message.author.id, @herc_user_id) do
      spam = User.mention(%User{id: @herc_user_id}) <> " bmw bad lmao"
      Api.create_message!(message.channel_id, spam)
    else
      spam =
        User.mention(%User{id: message.author.id}) <>
          " Don't be a jerk to the poor boi. he likes german cars"

      Api.create_message!(message.channel_id, spam)
    end
  end

  def handle_event({:MESSAGE_CREATE, %{content: "$" <> command} = message, _state}) do
    handle_command(command, message)
  end

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

  def handle_event(
        {:MESSAGE_CREATE, %{content: "!mock " <> text, channel_id: channel_id = message}, _state}
      ) do
    unless File.exists?("/tmp/spongemock") do
      Tesla.client([Tesla.Middleware.FollowRedirects])
      |> Tesla.get!(
        "https://github.com/ConnorRigby/spongemock/releases/download/v0.0.1/spongemock"
      )
      |> Map.fetch!(:body)
      |> (fn data ->
            File.write!("/tmp/spongemock", data)
            "/tmp/spongemock"
          end).()
      |> File.chmod(777)
    end

    {new_text, 0} = System.cmd("/tmp/spongemock", [text])
    _ = Api.delete_message!(message)
    _ = Api.create_message!(channel_id, new_text)
  end

  def handle_event({:MESSAGE_CREATE, %{channel_id: @memes_channel_id} = message, _state}) do
    CopyPastaWorker.activity(message)
    :noop
  end

  def handle_event({:MESSAGE_CREATE, %{channel_id: @verification_channel_id = message}, _state}) do
    case message.attachments do
      [%{url: url} | _rest] ->
        year = extract_year(message.content)
        params = %{image_url: url, discord_user_id: message.author.id, year: year}
        do_update(@verification_channel_id, message.author, params)

      _ ->
        :noop
    end
  end

  def handle_event({:GUILD_AVAILABLE, %{id: guild_id, members: members = guild}, _ws_state}) do
    # Logger.info("GUILD AVAILABLE: #{inspect(data, limit: :infinity)}")
    _ = GuildCache.Supervisor.start_child(guild)

    for {member_id, m} <- members do
      true = GuildCache.upsert_guild_member(guild_id, member_id, m)

      if @looking_for_miata_role_id in m.roles do
        ensure_looking_for_miata_timer(m)
      end
    end
  end

  def handle_event({:GUILD_MEMBER_UPDATE, guild_id, old, new = payload, _ws_state}) do
    Logger.info("guild member update: #{inspect(payload)}")
    GuildCache.upsert_guild_member(guild_id, new.user.id, new)

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
    # Logger.info("#{inspect(event, limit: :infinity)}")
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

  def handle_command("copypasta", %{channel_id: channel_id}) do
    do_copypasta(channel_id)
  end

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

  def handle_command("help", %{channel_id: channel_id}) do
    Api.create_message(channel_id, embed: @help_message)
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

  def handle_command("miatabot auth", message) do
    url = Application.get_env(:miata_bot, MiataBotWeb.PageController)[:auth_url]
    Api.create_message!(message.channel_id, url || "no url specified")
  end

  def handle_command(command, message) do
    Logger.debug("unknown command #{command}: #{inspect(message, limit: :infinity)}")
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

  def e85_stations_to_embed(stations) do
    embed =
      %Embed{}
      |> Embed.put_title("E85 search result")

    # |> Embed.put_description()
    # |> Embed.put_color(14_734_378)

    Enum.reduce(stations, embed, fn
      %{
        "station_name" => name,
        "street_address" => address,
        "city" => city,
        "state" => state,
        "station_phone" => phone,
        "access_days_time" => access_days_time
        # "e85_other_ethanol_blends" => blends
      },
      embed ->
        embed
        |> Embed.put_field(name || "unnamed station", """
        **Address**
        #{address} #{city}, #{state}

        **Phone Number**
        #{phone}

        **Access**
        #{access_days_time}
        """)

      _, embed ->
        embed
    end)
  end

  def do_copypasta(channel_id, attempts \\ 0)

  def do_copypasta(channel_id, 10) do
    Logger.error("failed to get any copypastas")
    Api.create_message(channel_id, "failed to get any copypastas")
  end

  def do_copypasta(channel_id, attempts) do
    paste = PastebinRandomizer.good_paste()
    copypasta = PastebinRandomizer.get(paste)

    case Api.create_message(channel_id, copypasta) do
      {:error, reason} ->
        Logger.error("copypasta randomizer error: #{inspect(reason)}")
        do_copypasta(channel_id, attempts + 1)

      _ ->
        :ok
    end
  end
end
