import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :miata_bot, MiataBot.Repo,
  # ssl: true,
  url: database_url,
  pool_size: 10
