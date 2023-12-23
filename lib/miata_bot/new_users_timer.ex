defmodule MiataBot.NewUsersTimer do
  use Ecto.Schema
  import Ecto.Changeset

  @enactment_date %DateTime{
    calendar: Calendar.ISO,
    day: 22,
    hour: 12,
    microsecond: {0, 0},
    minute: 0,
    month: 12,
    second: 0,
    std_offset: 0,
    time_zone: "Etc/UTC",
    utc_offset: 0,
    year: 2023,
    zone_abbr: "UTC"
  }

  schema "new_users" do
    field(:joined_at, :utc_datetime)
    field(:refreshed_at, :utc_datetime, default: @enactment_date)
    field(:discord_user_id, Snowflake)
    field(:discord_guild_id, Snowflake)
  end

  def changeset(new_user, params \\ %{}) do
    new_user
    |> cast(params, [
      :joined_at,
      :refreshed_at,
      :discord_user_id,
      :discord_guild_id
    ])
    |> unique_constraint([:discord_guild_id, :discord_user_id])
  end
end
