defmodule MiataBotDiscord.LookingForMiataListener do
  require Logger

  use Quarrel.Listener
  alias MiataBot.{Repo, LookingForMiataTimer}
  import Ecto.Query
  @expiry_days 69

  def debug_expire_timer(timer, refreshed_at \\ nil) do
    refreshed_at =
      refreshed_at ||
        %DateTime{
          calendar: Calendar.ISO,
          day: 20,
          hour: 19,
          microsecond: {0, 0},
          minute: 41,
          month: 6,
          second: 27,
          std_offset: 0,
          time_zone: "Etc/UTC",
          utc_offset: 0,
          year: 2019,
          zone_abbr: "UTC"
        }

    LookingForMiataTimer.changeset(timer, %{refreshed_at: refreshed_at})
    |> Repo.update!()
  end

  @impl GenServer
  def init(state) do
    send(self(), :checkup)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:checkup, state) do
    guild_id = state.guild.id
    timers = Repo.all(from t in LookingForMiataTimer, where: t.discord_guild_id == ^guild_id)
    {:noreply, state, {:continue, timers}}
  end

  @impl GenServer
  def handle_continue([timer | rest], state) do
    begin = timer.refreshed_at || timer.joined_at
    complete = Timex.shift(begin, days: @expiry_days)
    now = DateTime.utc_now()

    case Timex.compare(now, complete, :days) do
      -1 ->
        # now comes before compelte
        # timer is not up yet
        :ok

      0 ->
        # now is the same day as complete
        # timer is expired
        do_expire_timer(timer, state)

      1 ->
        # now is after complete
        # timer is expired
        do_expire_timer(timer, state)
    end

    {:noreply, state, {:continue, rest}}
  end

  def handle_continue([], state) do
    # Logger.info("checkup complete")
    Process.send_after(self(), :checkup, 300_000)
    {:noreply, state, :hibernate}
  end

  @impl Quarrel.Listener
  def handle_guild_available(_guild, state) do
    # for {_member_id, m} <- guild.members do
    #   if state.config.looking_for_miata_role_id in m.roles do
    #     ensure_looking_for_miata_timer(guild, m)
    #   end
    # end

    {:noreply, state}
  end

  @impl Quarrel.Listener
  def handle_guild_member_update(old, new, state) do
    if state.config.looking_for_miata_role_id in (new.roles -- old.roles) do
      Logger.info("refreshing timer for #{new.user_id}")
      timer = ensure_looking_for_miata_timer(state.guild, new)
      refresh_looking_for_miata_timer(state.guild, timer)
    end

    if state.config.looking_for_miata_role_id in (old.roles -- new.roles) do
      Logger.info("refreshing timer for #{new.user_id}")
      timer = ensure_looking_for_miata_timer(state.guild, new)
      Repo.delete!(timer)
    end

    {:noreply, state}
  end

  def ensure_looking_for_miata_timer(guild, member) do
    case Repo.get_by(LookingForMiataTimer,
           discord_user_id: member.user_id,
           discord_guild_id: guild.id
         ) do
      nil ->
        LookingForMiataTimer.changeset(%LookingForMiataTimer{}, %{
          joined_at: DateTime.utc_now(),
          discord_user_id: member.user_id,
          discord_guild_id: guild.id
        })
        |> Repo.insert!()

      timer ->
        timer
    end
  end

  def refresh_looking_for_miata_timer(_guild, timer) do
    LookingForMiataTimer.changeset(timer, %{
      refreshed_at: DateTime.utc_now()
    })
    |> Repo.update!()
  end

  def do_expire_timer(timer, state) do
    member = get_guild_member!(state.guild.id, timer.discord_user_id)

    Logger.info("expiring timer for member: #{inspect(member)}")

    with {:ok} <- remove_looking_for_miata(member.user_id, state),
         {:ok} <- add_accepted(member.user_id, state) do
      embed =
        %Embed{}
        |> Embed.put_title("LookingForMiataTimer")
        |> Embed.put_description("demoting LFM")
        |> Embed.put_field("User: ", "<@#{timer.discord_user_id}>")
        |> Embed.put_color(0xFF0000)
        |> Embed.put_footer("ID: #{timer.discord_user_id}")
        |> Embed.put_timestamp(to_string(DateTime.utc_now()))

      create_message!(state.config.bot_spam_channel_id, embed: embed)
      delete(timer)
    else
      {:error, error} ->
        fail_embed =
          %Embed{}
          |> Embed.put_title("LookingForMiataTimer")
          |> Embed.put_description("failed to demote LFM")
          |> Embed.put_field("User: ", "<@#{timer.discord_user_id}>")
          |> Embed.put_field("Error:", "#{inspect(error)}")
          |> Embed.put_color(0xFF0000)
          |> Embed.put_footer("ID: #{timer.discord_user_id}")
          |> Embed.put_timestamp(to_string(DateTime.utc_now()))

        create_message!(state.config.bot_spam_channel_id, embed: fail_embed)
        delete(timer)
    end
  catch
    _, error ->
      Logger.error("error doing miata timer thing idk: #{inspect(error)}")
      delete(timer)
  end

  def add_accepted(user_id, state) do
    add_guild_member_role(
      state.guild.id,
      user_id,
      state.config.accepted_role_id
    )
  end

  def remove_accepted(user_id, state) do
    remove_guild_member_role(
      state.guild.id,
      user_id,
      state.config.accepted_role_id
    )
  end

  def add_looking_for_miata(user_id, state) do
    add_guild_member_role(
      state.guild.id,
      user_id,
      state.config.looking_for_miata_role_id
    )
  end

  def remove_looking_for_miata(user_id, state) do
    remove_guild_member_role(
      state.guild.id,
      user_id,
      state.config.looking_for_miata_role_id
    )
  end

  defp delete(timer) do
    case Repo.get(LookingForMiataTimer, timer.id) do
      nil -> :ok
      timer -> Repo.delete!(timer)
    end
  end
end
