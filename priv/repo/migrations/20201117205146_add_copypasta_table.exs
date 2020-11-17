defmodule MiataBot.Repo.Migrations.AddCopypastaTable do
  use Ecto.Migration

  def change do
    create table(:copy_pastas) do
      add :content, :text, null: false
      add :created_by_discord_id, :string, null: false
      timestamps()
    end
  end
end
