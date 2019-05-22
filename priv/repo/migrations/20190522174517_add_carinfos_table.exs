defmodule MiataBot.Repo.Migrations.AddCarinfosTable do
  use Ecto.Migration

  def change do
    create table(:carinfos) do
      add :year, :integer
      add :color, :integer
      add :color_code, :string
      add :title, :string
      add :image_url, :string
      add :discord_user_id, :string
    end

    create unique_index(:carinfos, [:discord_user_id])
  end
end
