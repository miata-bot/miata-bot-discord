import Config

config :nostrum,
  token: System.get_env("DISCORD_TOKEN"),
  gateway_intents: :all,
  num_shards: :auto

config :miata_bot, MiataBot.Partpicker,
  api_token: System.get_env("PARTPICKER_API_TOKEN"),
  base_url: System.get_env("PARTPICKER_BASE_URL"),
  gateway_url: System.get_env("PARTPICKER_GATEWAY_URL")

config :miata_bot, TrackerGG, api_token: System.get_env("TRACKER_GG_TOKEN")

config :miata_bot,
  ecto_repos: [MiataBot.Repo, Quarrel.Repo]

# The values are defaulted in the code as well
config :quarrel, Quarrel.Application, dispatch: Quarrel.NostrumConsumer
config :quarrel, Quarrel.Listener, api: Nostrum.Api

config :quarrel, Quarrel.GuildSupervisor,
  children: [
    MiataBotDiscord.AnnoyingHListener,
    MiataBotDiscord.AutoreplyListener,
    MiataBotDiscord.CarinfoAttachmentListener,
    MiataBotDiscord.CarinfoListener,
    MiataBotDiscord.ChannelLimitsListener,
    MiataBotDiscord.InventoryListener,
    MiataBotDiscord.LookingForMiataListener,
    MiataBotDiscord.MemesChannelListener,
    MiataBotDiscord.SettingsListener,
    MiataBotDiscord.TCGListener
  ]

config :logger, backends: [:console, RingLogger]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
