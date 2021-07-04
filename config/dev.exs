use Mix.Config

# Configure your database
config :miata_bot, MiataBot.Repo,
  username: "postgres",
  password: "postgres",
  database: "miata_bot_dev",
  hostname: System.get_env("DATABSE_URL") || "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
