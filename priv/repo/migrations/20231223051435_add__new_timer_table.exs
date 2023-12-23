defmodule MiataBot.Repo.Migrations.Add_NewTimerTable do
  use Ecto.Migration

  def change do
    create table(:new_users) do
      add :refreshed_at, :utc_datetime
      add :joined_at, :utc_datetime
      add :discord_user_id, :string
      add :discord_guild_id, :string, default: "322080266761797633", null: false
    end

    create unique_index(:looking_for_miatas, [:discord_user_id, :discord_guild_id])
  end
end
