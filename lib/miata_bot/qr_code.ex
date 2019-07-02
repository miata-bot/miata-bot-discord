defmodule MiataBot.QRCode do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "qr_codes" do
    field(:discord_guild_id, MiataBot.Snowflake)
    field(:discord_channel_id, MiataBot.Snowflake)
    field(:discord_user_id, MiataBot.Snowflake)
    field(:message, :string)
    field(:scans, :integer, default: 0)
    timestamps()
  end

  def changeset(qr_code, params \\ %{}) do
    qr_code
    |> cast(params, [:discord_guild_id, :discord_channel_id, :discord_user_id, :message, :scans])
  end
end
