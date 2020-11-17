defmodule MiataBotDiscord.FakeDiscordSource do
  @moduledoc """
  Stub interface for dispatching Discord events
  """

  use GenServer
  require Logger

  def message_create(%Nostrum.Struct.Message{guild_id: guild_id} = message) do
    guild = %Nostrum.Struct.Guild{id: guild_id}
    MiataBotDiscord.Guild.EventDispatcher.dispatch(guild, {:MESSAGE_CREATE, message})
  end

  def message_create(content) do
    guild = default_guild()
    channel = default_channel()
    message_create(guild, channel, content)
  end

  def message_create(guild, channel, content) do
    message = default_message(guild, channel, content)
    MiataBotDiscord.Guild.EventDispatcher.dispatch(guild, {:MESSAGE_CREATE, message})
  end

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end

  def init_guild(%Nostrum.Struct.Guild{} = guild, %Nostrum.Struct.User{} = current_user) do
    Logger.info("GUILD_AVAILABLE: #{guild.name}")
    config = MiataBotDiscord.NostrumConsumer.get_or_create_config(guild)

    case MiataBotDiscord.GuildSupervisor.start_guild(guild, config, current_user) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      error ->
        Logger.error("Could not start guild: #{guild.name}: #{inspect(error)}")
        error
    end
  end

  def init_guild() do
    init_guild(default_guild(), default_user())
  end

  def default_user() do
    %Nostrum.Struct.User{
      avatar: nil,
      bot: true,
      discriminator: "4588",
      email: nil,
      id: 755_805_360_123_805_987,
      mfa_enabled: true,
      public_flags: %Nostrum.Struct.User.Flags{
        bug_hunter_level_1: false,
        bug_hunter_level_2: false,
        early_supporter: false,
        hypesquad_balance: false,
        hypesquad_bravery: false,
        hypesquad_brilliance: false,
        hypesquad_events: false,
        partner: false,
        staff: false,
        system: false,
        team_user: false,
        verified_bot: false,
        verified_developer: false
      },
      username: "MiataBot",
      verified: true
    }
  end

  def default_author do
    user = default_user()
    %{user | id: 805_755_805_360_123_987}
  end

  def default_config(guild) do
    MiataBotDiscord.NostrumConsumer.get_or_create_config(guild)
  end

  def default_guild do
    %Nostrum.Struct.Guild{
      afk_channel_id: nil,
      afk_timeout: 300,
      application_id: nil,
      channels: nil,
      default_message_notifications: 1,
      embed_channel_id: "643947340453118019",
      embed_enabled: true,
      emojis: [
        %Nostrum.Struct.Emoji{
          animated: false,
          id: 644_017_512_102_494_209,
          managed: false,
          name: "ping",
          require_colons: true,
          roles: [],
          user: nil
        }
      ],
      explicit_content_filter: 0,
      features: [],
      icon: "0c8e107405e53f0923deaa2a69cb504f",
      id: 643_947_339_895_013_416,
      joined_at: nil,
      large: nil,
      member_count: nil,
      members: nil,
      mfa_level: 0,
      name: "miata",
      owner_id: 316_741_621_498_511_363,
      region: "us-central",
      roles: %{
        643_947_339_895_013_416 => %Nostrum.Struct.Guild.Role{
          color: 0,
          hoist: false,
          id: 643_947_339_895_013_416,
          managed: false,
          mentionable: false,
          name: "@everyone",
          permissions: 104_324_689,
          position: 0
        }
      },
      splash: nil,
      system_channel_id: 643_947_340_453_118_019,
      unavailable: nil,
      verification_level: 2,
      voice_states: nil,
      widget_channel_id: 643_947_340_453_118_019,
      widget_enabled: true
    }
  end

  def default_channel do
    %Nostrum.Struct.Channel{
      application_id: nil,
      bitrate: nil,
      guild_id: 643_947_339_895_013_416,
      icon: nil,
      id: 644_744_557_166_329_420,
      last_message_id: nil,
      last_pin_timestamp: nil,
      name: "deleteme",
      nsfw: false,
      owner_id: nil,
      parent_id: 644_744_557_166_329_857,
      permission_overwrites: [],
      position: 53,
      recipients: nil,
      topic: nil,
      type: 0,
      user_limit: nil
    }
  end

  def default_message(guild, channel, content) do
    %Nostrum.Struct.Message{
      guild_id: guild.id,
      content: content,
      channel_id: channel.id,
      author: default_author(),
      member: %Nostrum.Struct.Guild.Member{
        nick: "asdf",
        user: default_user()
      }
    }
  end
end
