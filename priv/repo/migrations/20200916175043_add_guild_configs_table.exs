defmodule MiataBot.Repo.Migrations.AddGuildConfigsTable do
  use Ecto.Migration

  def change do
    create table(:guild_configs) do
      add :guild_id, :string
      add :verification_channel_id, :string
      add :memes_channel_id, :string
      add :general_channel_id, :string
      add :offtopic_channel_id, :string
      add :miata_fan_role_id, :string
      add :looking_for_miata_role_id, :string
      add :bot_spam_channel_id, :string
    end
  end
end
