use Mix.Config

# Configure your database
config :miata_bot, MiataBot.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "miata_bot_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :quarrel, Quarrel.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "quarrel_miata_bot_dev"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
