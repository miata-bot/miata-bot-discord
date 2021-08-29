import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

quarrel_database_url =
  URI.parse(database_url)
  |> Map.put(:path, "/miata_bot_quarrel")
  |> to_string

config :miata_bot, MiataBot.Repo,
  url: database_url,
  pool_size: 10

config :quarrel, Quarrel.Repo,
  url: quarrel_database_url,
  pool_size: 10
