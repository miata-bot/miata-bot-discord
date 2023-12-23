defmodule MiataBotDiscord.NewUsersListener do
  require Logger

  use Quarrel.Listener
  alias MiataBot.{Repo, NewUsersTimer}
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

    NewUsersTimer.changeset(timer, %{refreshed_at: refreshed_at})
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
    timers = Repo.all(from t in NewUsersTimer, where: t.discord_guild_id == ^guild_id)
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
    #   if state.config.accepted_role_id in m.roles do
    #     ensure_new_user_timer(guild, m)
    #   end
    # end

    {:noreply, state}
  end

  @impl Quarrel.Listener
  def handle_guild_member_update(old, new, state) do
    if state.config.accepted_role_id in (new.roles -- old.roles) do
      Logger.info("refreshing timer for #{new.user_id}")
      timer = ensure_new_user_timer(state.guild, new)
      refresh_looking_for_miata_timer(state.guild, timer)
    end

    if state.config.accepted_role_id in (old.roles -- new.roles) do
      Logger.info("refreshing timer for #{new.user_id}")
      timer = ensure_new_user_timer(state.guild, new)
      Repo.delete!(timer)
    end

    {:noreply, state}
  end

  def ensure_new_user_timer(guild, member) do
    case Repo.get_by(NewUsersTimer,
           discord_user_id: member.user_id,
           discord_guild_id: guild.id
         ) do
      nil ->
        NewUsersTimer.changeset(%NewUsersTimer{}, %{
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
    NewUsersTimer.changeset(timer, %{
      refreshed_at: DateTime.utc_now()
    })
    |> Repo.update!()
  end

  def do_expire_timer(timer, state) do
    member = get_guild_member!(state.guild.id, timer.discord_user_id)

    Logger.info("expiring new user timer for member: #{inspect(member)}")

    Nostrum.Api.remove_guild_member(state.guild.id, timer.discord_user_id)
    delete(timer)
  catch
    _, error ->
      Logger.error("error doing user timer thing idk: #{inspect(error)}")
      delete(timer)
  end

  defp delete(timer) do
    case Repo.get(NewUsersTimer, timer.id) do
      nil -> :ok
      timer -> Repo.delete!(timer)
    end
  end
end
