defmodule MiataBot.Repo.Migrations.UpdateLfmTimer do
  use Ecto.Migration

  def change do
    alter table(:guild_configs) do
      add :accepted_role_id, :string
    end
  end
end
