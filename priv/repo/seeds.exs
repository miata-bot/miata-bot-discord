# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MiataBot.Repo.insert!(%MiataBot.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

%MiataBotDiscord.Guild.Config{
  guild_id: 643_947_339_895_013_416,
  verification_channel_id: 778_325_814_986_014_731,
  memes_channel_id: 778_325_951_989_284_894,
  general_channel_id: 778_334_280_337_719_357,
  offtopic_channel_id: 778_334_306_002_927_646,
  miata_fan_role_id: 778_337_478_578_405_387
}
|> MiataBot.Repo.insert!()
