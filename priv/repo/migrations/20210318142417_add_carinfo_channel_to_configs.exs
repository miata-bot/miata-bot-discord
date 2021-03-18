defmodule MiataBot.Repo.Migrations.AddCarinfoChannelToConfigs do
  use Ecto.Migration

  def change do
    alter table(:guild_configs) do
      add :carinfo_channel_id, :binary
    end
  end
end
