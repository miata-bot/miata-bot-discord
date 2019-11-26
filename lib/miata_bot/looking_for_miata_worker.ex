defmodule MiataBot.LookingForMiataWorker do
  use GenServer
  require Logger
  alias Nostrum.Struct.Embed
  alias MiataBot.{GuildCache, Repo, LookingForMiataTimer}
  # @seconds_in_a_day 86400
  @miata_discord_guild_id 322_080_266_761_797_633
  @looking_for_miata_role_id 504_088_951_485_890_561
  @miata_fan_role_id 439_493_557_301_280_789
  @bot_spam_channel_id 351_767_273_712_910_336

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args) do
    send(self(), :checkup)
    {:ok, []}
  end

  def handle_info(:checkup, _state) do
    {:noreply, Repo.all(LookingForMiataTimer), {:continue, :work}}
  end

  def handle_continue(:work, [timer | rest]) do
    begin = timer.refreshed_at || timer.joined_at
    complete = Timex.shift(begin, days: 30)
    now = DateTime.utc_now()

    case Timex.compare(now, complete, :days) do
      -1 ->
        # now comes before compelte
        # timer is not up yet
        :ok

      0 ->
        # now is the same day as complete
        # timer is expired
        do_expire_timer(timer)

      1 ->
        # now is after complete
        # timer is expired
        do_expire_timer(timer)
    end

    {:noreply, rest, {:continue, :work}}
  end

  def handle_continue(:work, []) do
    Process.send_after(self(), :checkup, 300_000)
    {:noreply, [], :hibernate}
  end

  def do_expire_timer(timer) do
    member =
      GuildCache.get_guild_member(@miata_discord_guild_id, timer.discord_user_id) ||
        Nostrum.Api.get_guild_member!(@miata_discord_guild_id, timer.discord_user_id)

    Logger.info("expiring timer for member: #{inspect(member)}")

    with {:ok} <- remove_looking_for_miata(member.user.id),
         {:ok} <- add_miata_fan(member.user.id) do
      embed =
        %Embed{}
        |> Embed.put_color(1_146_534)
        |> Embed.put_author(
          "#{member.user.username}##{member.user.discriminator}",
          nil,
          "https://cdn.discordapp.com/avatars/#{member.user.id}/#{member.user.avatar}?size=128"
        )
        |> Embed.put_description(
          "**#{Nostrum.Struct.Guild.Member.mention(member)} will be demoted**"
        )
        |> Embed.put_footer("ID: #{member.user.id}")

      Nostrum.Api.create_message!(@bot_spam_channel_id, embed: embed)
    else
      {:error, error} ->
        fail_embed =
          %Embed{}
          |> Embed.put_color(1_146_534)
          |> Embed.put_author(
            "#{member.user.username}##{member.user.discriminator}",
            nil,
            "https://cdn.discordapp.com/avatars/#{member.user.id}/#{member.user.avatar}?size=128"
          )
          |> Embed.put_description(
            "**#{Nostrum.Struct.Guild.Member.mention(member)} could not be demoted: #{
              inspect(error)
            } **"
          )
          |> Embed.put_footer("ID: #{member.user.id}")

        Nostrum.Api.create_message!(@bot_spam_channel_id, embed: fail_embed)
    end
  end

  def add_miata_fan(user_id) do
    Nostrum.Api.add_guild_member_role(@miata_discord_guild_id, user_id, @miata_fan_role_id)
  end

  def remove_miata_fan(user_id) do
    Nostrum.Api.remove_guild_member_role(@miata_discord_guild_id, user_id, @miata_fan_role_id)
  end

  def add_looking_for_miata(user_id) do
    Nostrum.Api.add_guild_member_role(
      @miata_discord_guild_id,
      user_id,
      @looking_for_miata_role_id
    )
  end

  def remove_looking_for_miata(user_id) do
    Nostrum.Api.remove_guild_member_role(
      @miata_discord_guild_id,
      user_id,
      @looking_for_miata_role_id
    )
  end
end
