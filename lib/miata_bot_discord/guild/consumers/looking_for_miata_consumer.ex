def handle_event({:GUILD_AVAILABLE, {%{id: guild_id, members: members} = guild}, _ws_state}) do
  Logger.info("GUILD AVAILABLE: #{inspect(guild, limit: :infinity)}")

  case GuildCache.Supervisor.start_child(guild) do
    {:ok, pid} ->
      Logger.info("Started guild cache #{guild.id}: #{inspect(pid)}")

    {:error, reason} ->
      Logger.error(
        "Failed to start guild cache: #{guild.id}: #{inspect(reason, limit: :infinity)}"
      )
  end

  for {member_id, m} <- members do
    true = GuildCache.upsert_guild_member(guild_id, member_id, m)

    if @looking_for_miata_role_id in m.roles do
      ensure_looking_for_miata_timer(m)
    end
  end
end

def handle_event({:GUILD_MEMBER_UPDATE, {guild_id, old, new} = payload, _ws_state}) do
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
  case elem(event, 0) do
    :PRESENCE_UPDATE ->
      :ok

    :TYPING_START ->
      :ok

    # :MESSAGE_UPDATE ->
    #   :ok

    _ ->
      Logger.info("#{inspect(event, limit: :infinity)}")
  end

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
