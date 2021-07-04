import Config

config :nostrum,
  token: System.get_env("DISCORD_TOKEN") || "${DISCORD_TOKEN}",
  gateway_intents: [
    :guilds,
    :guild_members,
    :guild_bans,
    :guild_emojis,
    :guild_integrations,
    :guild_webhooks,
    :guild_invites,
    :guild_voice_states,
    :guild_presences,
    :guild_messages,
    :guild_message_reactions,
    :guild_message_typing,
    :direct_messages,
    :direct_message_reactions,
    :direct_message_typing
  ],
  num_shards: :auto

config :miata_bot, MiataBot.Partpicker, api_token: System.get_env("PARTPICKER_API_TOKEN")

config :miata_bot, MiataBotWeb.PageController, auth_url: System.get_env("DISCORD_AUTH_URL")

config :miata_bot, Nrel, api_key: System.get_env("NREL_API_KEY")

config :miata_bot,
  ecto_repos: [MiataBot.Repo]

config :logger, backends: [:console, RingLogger]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
