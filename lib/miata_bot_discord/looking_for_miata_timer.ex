defmodule MiataBot.LookingForMiataTimer do
  use Ecto.Schema
  import Ecto.Changeset

  @enactment_date %DateTime{
    calendar: Calendar.ISO,
    day: 20,
    hour: 19,
    microsecond: {0, 0},
    minute: 41,
    month: 6,
    second: 27,
    std_offset: 0,
    time_zone: "Etc/UTC",
    utc_offset: 0,
    year: 2019,
    zone_abbr: "UTC"
  }

  schema "looking_for_miatas" do
    field(:joined_at, :utc_datetime)
    field(:refreshed_at, :utc_datetime, default: @enactment_date)
    field(:discord_user_id, Snowflake)
  end

  def changeset(looking_for_miata, params \\ %{}) do
    looking_for_miata
    |> cast(params, [:joined_at, :refreshed_at, :discord_user_id])
    |> unique_constraint(:discord_user_id)
  end
end
