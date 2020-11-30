defmodule MiataBot.Carinfo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "carinfos" do
    field(:year, :integer)
    field(:color, :integer)
    field(:color_code, :string)
    field(:title, :string)
    field(:image_url, :string)
    field(:wheels, :string)
    field(:tires, :string)
    field(:discord_user_id, Snowflake)
    field(:instagram_handle, :string)
  end

  def changeset(carinfo, params \\ %{}) do
    carinfo
    |> cast(params, [
      :year,
      :color,
      :color_code,
      :title,
      :image_url,
      :discord_user_id,
      :wheels,
      :tires,
      :instagram_handle
    ])
    |> validate_inclusion(:year, 1989..2020)
    |> unique_constraint(:discord_user_id)
    |> validate_instagram()
  end

  def validate_instagram(changeset) do
    if handle = get_change(changeset, :instagram_handle) do
      if is_valid_handle?(handle) do
        ensure_at_sign(changeset, handle)
      else
        add_error(changeset, :instagram_handle, "is invalid")
      end
    else
      changeset
    end
  end

  def ensure_at_sign(changeset, "@" <> _ = handle) do
    put_change(changeset, :instagram_handle, handle)
  end

  def ensure_at_sign(changeset, handle) do
    ensure_at_sign(changeset, "@" <> handle)
  end

  def is_valid_handle?(handle) do
    Regex.match?(
      ~r/^([A-Za-z0-9_](?:(?:[A-Za-z0-9_]|(?:\.(?!\.))){0,28}(?:[A-Za-z0-9_]))?)$/,
      handle
    ) ||
      Regex.match?(
        ~r/^@([A-Za-z0-9_](?:(?:[A-Za-z0-9_]|(?:\.(?!\.))){0,28}(?:[A-Za-z0-9_]))?)$/,
        handle
      )
  end
end
