defmodule MiataBot.Repo.Migrations.AddMoreCarinfo do
  use Ecto.Migration

  def change do
    alter table(:carinfos) do
      add :wheels, :string
      add :tires, :string
    end
  end
end
