defmodule MiataBot.Repo do
  use Ecto.Repo,
    otp_app: :miata_bot,
    adapter: Ecto.Adapters.Postgres
end
