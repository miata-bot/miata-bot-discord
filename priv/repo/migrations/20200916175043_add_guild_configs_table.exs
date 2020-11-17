defmodule MiataBot.Repo.Migrations.AddGuildConfigsTable do
  use Ecto.Migration

  def change do
    create table(:guild_configs) do
      add :guild_id, :string
      add :verification_channel_id, :string
      add :memes_channel_id, :string
    end
  end
end
