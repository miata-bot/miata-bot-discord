defmodule MiataBot.Carinfo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "carinfos" do
    field(:year, :integer)
    field(:color, :integer)
    field(:color_code, :string)
    field(:title, :string)
    field(:image_url, :string)
    field(:discord_user_id, Snowflake)
  end

  def changeset(carinfo, params \\ %{}) do
    carinfo
    |> cast(params, [:year, :color, :color_code, :title, :image_url, :discord_user_id])
    |> validate_inclusion(:year, 1989..2020)
    |> unique_constraint(:discord_user_id)
  end
end
