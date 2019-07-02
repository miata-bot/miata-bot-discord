defmodule MiataBot.Repo.Migrations.AddQrScans do
  use Ecto.Migration

  def change do
    alter table(:qr_codes) do
      add(:scans, :integer, default: 0)
    end
  end
end
