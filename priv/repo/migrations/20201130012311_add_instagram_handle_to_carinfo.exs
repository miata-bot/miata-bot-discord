defmodule MiataBot.Repo.Migrations.AddInstagramHandleToCarinfo do
  use Ecto.Migration

  def change do
    alter table(:carinfos) do
      add :instagram_handle, :string
    end
  end
end
