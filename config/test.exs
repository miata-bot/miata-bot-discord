use Mix.Config

# Configure your database
config :miata_bot, MiataBot.Repo,
  username: "postgres",
  password: "postgres",
  database: "miata_bot_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Print only warnings and errors during test
config :logger, level: :warn
