defmodule MiataBot.Repo.Migrations.CreateQrsTable do
  use Ecto.Migration


  def change do
    create table(:qr_codes, primary_key: false) do
      add :id, :binary_id, [primary_key: true]
      add :discord_guild_id, :string
      add :discord_user_id, :string
      add :discord_channel_id, :string
      add :message, :string
      timestamps()
    end
  end
end
