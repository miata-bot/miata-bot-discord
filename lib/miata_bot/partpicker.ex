defmodule MiataBot.Partpicker do
  @api_token Application.get_env(:miata_bot, __MODULE__)[:api_token]
  # @api_token || Mix.raise("missing api token")

  use Tesla
  plug Tesla.Middleware.BaseUrl, "https://miatapartpicker.gay/api"
  plug Tesla.Middleware.Headers, [{"authorization", "bearer #{@api_token}"}]
  plug Tesla.Middleware.JSON

  defmodule Build do
    use Ecto.Schema
    @primary_key {:uid, :string, [autogenerate: false]}
    embedded_schema do
      field :banner_photo_id, :binary_id
      field :banner_photo_url, :string
      field :color, :string
      field :description, :string
      field :make, :string
      field :model, :string

      embeds_many :photos, Photo, primary_key: {:uuid, :binary_id, [autogenerate: false]} do
        field :filename, :string
        field :url, :string
      end

      embeds_one :user, User, primary_key: false do
        field :discord_user_id, Snowflake
        field :instagram_handle, :string
      end

      field :tires, :string
      field :wheels, :string
      field :year, :integer
    end
  end

  def builds(discord_user_id) do
    %{body: body} = get!("/builds/#{discord_user_id}")
    Enum.map(body, &parse_build/1)
  end

  def build(discord_user_id, build_uid) do
    %{body: body} = get!("/builds/#{discord_user_id}/#{build_uid}")
    parse_build(body)
  end

  def parse_build(attrs) do
    Ecto.Changeset.cast(%Build{}, attrs, [
      :banner_photo_id,
      :color,
      :description,
      :make,
      :model,
      :tires,
      :uid,
      :wheels,
      :year
    ])
    |> Ecto.Changeset.cast_embed(:photos, with: &photo_changeset/2)
    |> Ecto.Changeset.cast_embed(:user, with: &user_changeset/2)
    |> put_photo_url(:banner_photo_url, :banner_photo_id)
    |> Ecto.Changeset.apply_changes()
  end

  def photo_changeset(photo, attrs) do
    photo
    |> Ecto.Changeset.cast(attrs, [:filename, :uuid])
    |> put_photo_url(:url, :uuid)
  end

  def put_photo_url(changeset, field, uuid_field) do
    if uuid = Ecto.Changeset.get_field(changeset, uuid_field) do
      Ecto.Changeset.put_change(changeset, field, "https://miatapartpicker.gay/media/#{uuid}")
    else
      changeset
    end
  end

  def user_changeset(user, attrs) do
    user
    |> Ecto.Changeset.cast(attrs, [:discord_user_id, :instagram_handle])
  end
end
