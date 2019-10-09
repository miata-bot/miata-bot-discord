use Mix.Config

# Configure your database
config :miata_bot, MiataBot.Repo,
  username: "postgres",
  password: "postgres",
  database: "miata_bot_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :miata_bot, MiataBotWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
