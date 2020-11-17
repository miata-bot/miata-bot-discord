defmodule MiataBotDiscord.Guild.LookingForMiataConsumer do
  @moduledoc """
  Processes commands from users
  """

  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.EventDispatcher
  alias MiataBot.{Repo, LookingForMiataTimer}

  alias Nostrum.Struct.Guild

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

        {:GUILD_AVAILABLE, %Guild{} = guild}, {actions, state} ->
          handle_guild_available(guild, {actions, state})

        {:GUILD_MEMBER_UPDATE, old, new}, {actions, state} ->
          handle_guild_member_update(old, new, {actions, state})

        _, {actions, state} ->
          {actions, state}
      end)

    {:noreply, actions, state}
  end

  def handle_guild_available(%Guild{} = guild, {actions, state}) do
    for {_member_id, m} <- guild.members do
      if state.config.looking_for_miata_role_id in m.roles do
        ensure_looking_for_miata_timer(guild, m)
      end
    end

    {actions, state}
  end

  def handle_guild_member_update(old, new, {actions, state}) do
    Logger.info("GUILD_MEMBER_UPDATE")

    if state.config.looking_for_miata_role_id in (new.roles -- old.roles) do
      Logger.info("refreshing timer for #{new.user.username}")
      timer = ensure_looking_for_miata_timer(state.guild, new)
      refresh_looking_for_miata_timer(state.guild, timer)
    end

    if state.config.looking_for_miata_role_id in (old.roles -- new.roles) do
      Logger.info("refreshing timer for #{new.user.username}")
      timer = ensure_looking_for_miata_timer(state.guild, new)
      Repo.delete!(timer)
    end

    {actions, state}
  end

  defp ensure_looking_for_miata_timer(guild, member) do
    case Repo.get_by(LookingForMiataTimer,
           discord_user_id: member.user.id,
           discord_guild_id: guild.id
         ) do
      nil ->
        LookingForMiataTimer.changeset(%LookingForMiataTimer{}, %{
          joined_at: member.joined_at,
          discord_user_id: member.user.id,
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
end
