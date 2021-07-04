defmodule MiataBot.Repo.Migrations.AddInteractionsToGuildConfig do
  use Ecto.Migration

  def change do
    alter table(:guild_configs) do
      add :interactions, {:array, :map}, default: []
    end
  end
end
