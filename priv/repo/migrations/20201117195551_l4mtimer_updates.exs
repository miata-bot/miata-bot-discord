defmodule MiataBot.Repo.Migrations.L4mtimerUpdates do
  use Ecto.Migration

  def change do
    drop unique_index(:looking_for_miatas, [:discord_user_id])

    alter table(:looking_for_miatas) do
      add :discord_guild_id, :string, default: "322080266761797633", null: false
    end

    alter table(:looking_for_miatas) do
      modify :discord_guild_id, :string, default: nil, null: false
    end

    create unique_index(:looking_for_miatas, [:discord_guild_id, :discord_user_id])
  end
end
