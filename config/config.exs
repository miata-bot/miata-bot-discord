# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :nostrum,
  token: System.get_env("DISCORD_TOKEN") || "${DISCORD_TOKEN}",
  num_shards: :auto

config :miata_bot,
  ecto_repos: [MiataBot.Repo]

# Configures the endpoint
config :miata_bot, MiataBotWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "bMgF4nNbm7GThARLJUuKMhoMWzj3aw2MxDEkFeX7vSaxTgWtm5qs5/UvbA3DG2B3",
  render_errors: [view: MiataBotWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: MiataBot.PubSub, adapter: Phoenix.PubSub.PG2]

config :miata_bot, MiataBotWeb.HerokuTask, url: System.get_env("APP_URL")

config :logger, backends: [:console, RingLogger]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
