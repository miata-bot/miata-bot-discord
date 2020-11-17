defmodule MiataBotDiscord do
  alias MiataBot.{
    Repo,
    CopyPastaWorker,
    Carinfo,
    GuildCache,
    LookingForMiataTimer
  }

  import MiataBotDiscord.Util

  require Logger

  use Nostrum.Consumer
  alias Nostrum.Api
  alias Nostrum.Struct.{Embed, User}

  @josh_user_id 149_677_654_101_065_728
  @herc_user_id 226_052_366_745_600_000

  @miata_discord_guild_id 322_080_266_761_797_633
  @general_channel_id 322_080_266_761_797_633
  # 322080266761797633
  @verification_channel_id 322_127_502_212_333_570
  @looking_for_miata_role_id 504_088_951_485_890_561
  @miata_fan_role_id 439_493_557_301_280_789
  @maysh_user_id 326_204_806_165_430_273
  # @justin_user_id 126_155_471_886_352_385
  # @easyy_user_id 151_099_008_230_752_256
  @memes_channel_id 555_431_196_884_992_000
  @bot_spam_channel_id 351_767_273_712_910_336

  Module.register_attribute(__MODULE__, :bangs, accumulate: true)

  @na_role_id 322_082_252_320_145_408
  @nb_role_id 322_082_375_578_419_210
  @nc_role_id 322_082_487_243_112_448
  @nd_role_id 322_082_550_640_279_553
  @accepted_role_id 591_899_819_132_583_936

  def list_unverified do
    unverified =
      @miata_discord_guild_id
      |> MiataBot.GuildCache.get_guild()
      |> Map.get(:members)
      |> Enum.filter(fn {_user_id, %{roles: roles, joined_at: joined_at}} ->
        with {:ok, %DateTime{} = dt, _} <- DateTime.from_iso8601(joined_at),
             day_difference when day_difference < 14 <- Timex.diff(DateTime.utc_now(), dt, :days) do
          @accepted_role_id in roles
        else
          _ -> false
        end
      end)

    embed =
      %Embed{}
      |> Embed.put_title("Unverified members")
      |> Embed.put_description("someone should check these members out")

    embed =
      Enum.reduce(unverified, embed, fn
        {_, member}, embed ->
          Embed.put_field(
            embed,
            "**#{member.nick || member.user.username} (#{member.user.id}) **",
            "needs verification"
          )
      end)

    Nostrum.Api.create_message!(@bot_spam_channel_id, embed: embed)
  end

  def verify_user(user_id, roles) do
    roles =
      Enum.map(roles, fn
        "na" -> @na_role_id
        "nb" -> @nb_role_id
        "nc" -> @nc_role_id
        "nd" -> @nd_role_id
      end)

    for role_id <- roles do
      Logger.info("Assigning role:#{role_id} to user:#{user_id}")

      Nostrum.Api.create_message!(
        @bot_spam_channel_id,
        "Assigning role:#{role_id} to user:#{user_id}"
      )

      {:ok} =
        Nostrum.Api.add_guild_member_role(
          @miata_discord_guild_id,
          user_id,
          role_id,
          "miata bot verification"
        )
    end
  end

  def start_link do
    Consumer.start_link(__MODULE__, name: __MODULE__)
  end

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

  def handle_command("miatabot auth", message) do
    url = Application.get_env(:miata_bot, MiataBotWeb.PageController)[:auth_url]
    Api.create_message!(message.channel_id, url || "no url specified")
  end

  def handle_command(command, message) do
    Logger.debug("unknown command #{command}: #{inspect(message, limit: :infinity)}")
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
