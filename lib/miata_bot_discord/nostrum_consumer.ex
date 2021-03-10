defmodule MiataBotDiscord.NostrumConsumer do
  @moduledoc false

  use Nostrum.Consumer
  require Logger

  @doc "Fetches a guild config"
  def get_or_create_config(%Nostrum.Struct.Guild{id: guild_id}) do
    alias MiataBot.Repo

    case Repo.get_by(MiataBotDiscord.Guild.Config, guild_id: guild_id) do
      nil -> Repo.insert!(%MiataBotDiscord.Guild.Config{guild_id: guild_id})
      config -> config
    end
  end

  @doc false
  def start_link() do
    Consumer.start_link(__MODULE__)
  end

  @impl Nostrum.Consumer
  def handle_event(
        {:GUILD_UNAVAILABLE, %Nostrum.Struct.Guild.UnavailableGuild{} = unavailable, _ws_state}
      ) do
    Logger.info("GUILD_UNAVAILABLE: #{inspect(unavailable)}")
  end

  def handle_event({:GUILD_CREATE, {guild}, _ws_state}) do
    Logger.info("GUILD_AVAILABLE: #{guild.name}")
    {:ok, current_user} = Nostrum.Api.get_current_user()
    config = get_or_create_config(guild)

    case MiataBotDiscord.GuildSupervisor.start_guild(guild, config, current_user) do
      {:ok, _pid} ->
        MiataBotDiscord.Guild.EventDispatcher.dispatch(guild, {:GUILD_AVAILABLE, guild})
        :ok

      {:error, {:already_started, _pid}} ->
        MiataBotDiscord.Guild.EventDispatcher.dispatch(guild, {:GUILD_AVAILABLE, guild})
        :ok

      error ->
        Logger.error("Could not start guild: #{guild.name}: #{inspect(error)}")
    end

    for {member_id, m} <- guild.members do
      true = MiataBotDiscord.GuildCache.upsert_guild_member(guild.id, member_id, m)
    end
  end

  def handle_event({:GUILD_AVAILABLE, %Nostrum.Struct.Guild{} = guild, _ws_state}) do
    Logger.info("GUILD_AVAILABLE: #{guild.name}")
    {:ok, current_user} = Nostrum.Api.get_current_user()
    config = get_or_create_config(guild)

    case MiataBotDiscord.GuildSupervisor.start_guild(guild, config, current_user) do
      {:ok, _pid} ->
        MiataBotDiscord.Guild.EventDispatcher.dispatch(guild, {:GUILD_AVAILABLE, guild})
        :ok

      {:error, {:already_started, _pid}} ->
        MiataBotDiscord.Guild.EventDispatcher.dispatch(guild, {:GUILD_AVAILABLE, guild})
        :ok

      error ->
        Logger.error("Could not start guild: #{guild.name}: #{inspect(error)}")
    end

    for {member_id, m} <- guild.members do
      true = MiataBotDiscord.GuildCache.upsert_guild_member(guild.id, member_id, m)
    end
  end

  def handle_event({:GUILD_MEMBER_UPDATE, {guild_id, old, new} = payload, _ws_state}) do
    Logger.info("guild member update: #{inspect(payload)}")
    MiataBotDiscord.GuildCache.upsert_guild_member(guild_id, new.user.id, new)
    MiataBotDiscord.Guild.EventDispatcher.dispatch(guild_id, {:GUILD_MEMBER_UPDATE, old, new})
  end

  def handle_event({:GUILD_MEMBER_ADD, {guild_id, new} = payload, _ws_state}) do
    Logger.info("guild member add: #{inspect(payload)}")
    MiataBotDiscord.GuildCache.upsert_guild_member(guild_id, new.user.id, new)
    MiataBotDiscord.Guild.EventDispatcher.dispatch(guild_id, {:GUILD_MEMBER_ADD, new})
  end

  def handle_event({:READY, _ready, _ws_state}) do
    :noop
  end

  def handle_event(
        {:MESSAGE_CREATE, %Nostrum.Struct.Message{guild_id: guild_id} = message, _ws_state}
      ) do
    guild = %Nostrum.Struct.Guild{id: guild_id}
    # Logger.info("message: #{inspect(message, limit: :infinity)}")
    MiataBotDiscord.Guild.EventDispatcher.dispatch(guild, {:MESSAGE_CREATE, message})
  end

  def handle_event({:MESSAGE_REACTION_ADD, %{guild_id: guild_id} = reaction, _ws_state}) do
    guild = %Nostrum.Struct.Guild{id: guild_id}
    MiataBotDiscord.Guild.EventDispatcher.dispatch(guild, {:MESSAGE_REACTION_ADD, reaction})
  end

  def handle_event(
        {:MESSAGE_UPDATE, %Nostrum.Struct.Message{guild_id: guild_id} = message, _ws_state}
      ) do
    guild = %Nostrum.Struct.Guild{id: guild_id}
    MiataBotDiscord.Guild.EventDispatcher.dispatch(guild, {:MESSAGE_UPDATE, message})
  end

  def handle_event({:PRESENCE_UPDATE, {guild_id, old, new}, _ws_state}) do
    guild = %Nostrum.Struct.Guild{id: guild_id}
    MiataBotDiscord.Guild.EventDispatcher.dispatch(guild, {:PRESENCE_UPDATE, {old, new}})
  end

  def handle_event({:TYPING_START, %{channel_id: _channel_id} = _typing_start, _ws_state}) do
    # guild = %Nostrum.Struct.Guild{id: guild_id}
    # MiataBotDiscord.Guild.EventDispatcher.dispatch(guild, {:TYPING_START, typing_start})
    :noop
  end

  def handle_event({:CHANNEL_CREATE, %{guild_id: guild_id} = channel_create, _ws_state}) do
    guild = %Nostrum.Struct.Guild{id: guild_id}
    MiataBotDiscord.Guild.EventDispatcher.dispatch(guild, {:CHANNEL_CREATE, channel_create})
  end

  def handle_event(
        {:CHANNEL_UPDATE,
         {%{guild_id: guild_id} = old_channel, %{guild_id: guild_id} = new_update}, _ws_state}
      ) do
    guild = %Nostrum.Struct.Guild{id: guild_id}

    MiataBotDiscord.Guild.EventDispatcher.dispatch(
      guild,
      {:CHANNEL_UPDATE, {old_channel, new_update}}
    )
  end

  def handle_event({:CHANNEL_DELETE, %{guild_id: guild_id} = channel_delete, _ws_state}) do
    guild = %Nostrum.Struct.Guild{id: guild_id}
    MiataBotDiscord.Guild.EventDispatcher.dispatch(guild, {:CHANNEL_DELETE, channel_delete})
  end

  def handle_event(
        {:USER_UPDATE, {%{guild_id: guild_id} = old, %{guild_id: guild_id} = new}, _ws_state}
      ) do
    guild = %Nostrum.Struct.Guild{id: guild_id}
    MiataBotDiscord.Guild.EventDispatcher.dispatch(guild, {:USER_UPDATE, {old, new}})
  end

  def handle_event(event) do
    Logger.error(["Unhandled event from Nostrum ", inspect(event, pretty: true)])
  end
end
