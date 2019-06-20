defmodule MiataBot.Repo.Migrations.AddL4mTimerTable do
  use Ecto.Migration

  def change do
    create table(:looking_for_miatas) do
      add :refreshed_at, :utc_datetime
      add :joined_at, :utc_datetime
      add :discord_user_id, :string
    end

    create unique_index(:looking_for_miatas, [:discord_user_id])
  end
end
