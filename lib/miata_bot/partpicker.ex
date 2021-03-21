defmodule MiataBot.Partpicker do
  @api_token Application.get_env(:miata_bot, __MODULE__)[:api_token]
  # @api_token || Mix.raise("missing api token")

  use Tesla
  plug Tesla.Middleware.BaseUrl, "https://miatapartpicker.gay/api"
  # plug Tesla.Middleware.BaseUrl, "http://localhost:4000/api"

  plug Tesla.Middleware.Headers, [{"authorization", "Bearer #{@api_token}"}]
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
      field :vin, :string
      field :mileage, :integer

      embeds_many :photos, Photo, primary_key: {:uuid, :binary_id, [autogenerate: false]} do
        field :filename, :string
        field :url, :string
      end

      field :tires, :string
      field :wheels, :string
      field :year, :integer
    end
  end

  defmodule User do
    use Ecto.Schema
    @primary_key {:discord_user_id, Snowflake, [autogenerate: false]}
    embedded_schema do
      field :instagram_handle, :string
      field :prefered_unit, Ecto.Enum, values: [:km, :miles]
      field :hand_size, :float
      embeds_many :builds, Build
      embeds_one :featured_build, Build
    end
  end

  def user(discord_user_id) do
    case get!("/users/#{discord_user_id}") do
      %{status: 200, body: body} -> {:ok, parse_user(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
    end
  end

  def create_user(discord_user_id) do
    case post!("/users/", %{user: %{discord_user_id: discord_user_id}}) do
      %{status: 201, body: body} -> {:ok, parse_user(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
    end
  end

  def update_user_featured_build(discord_user_id, featured_build_uid) do
    attrs = %{featured_build_id: featured_build_uid}

    case put!("/users/#{discord_user_id}/featured_build", attrs) do
      %{status: 202, body: body} -> {:ok, parse_user(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
    end
  end

  def update_user(discord_user_id, params) do
    case put!("/users/#{discord_user_id}", %{user: params}) do
      %{status: 202, body: body} -> {:ok, parse_user(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
      %{status: _, body: body} when is_binary(body) -> {:error, %{"error" => [body]}}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def create_build(discord_user_id, params) do
    case post!("/users/#{discord_user_id}/builds/", %{build: params}) do
      %{status: 201, body: body} -> {:ok, parse_build(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
      %{status: _, body: body} when is_binary(body) -> {:error, %{"error" => [body]}}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def update_build(discord_user_id, build_uid, params) do
    case put!("/users/#{discord_user_id}/builds/#{build_uid}", %{build: params}) do
      %{status: 202, body: body} -> {:ok, parse_build(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
      %{status: _, body: body} when is_binary(body) -> {:error, %{"error" => [body]}}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def builds(discord_user_id) do
    case get!("/users/#{discord_user_id}/builds/") do
      %{status: 200, body: body} -> {:ok, Enum.map(body, &parse_build/1)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
      %{status: _, body: body} when is_binary(body) -> {:error, %{"error" => [body]}}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def build(discord_user_id, build_uid) do
    case get!("/users/#{discord_user_id}/builds/#{build_uid}") do
      %{status: 200, body: body} when is_list(body) -> {:ok, Enum.map(body, &parse_build/1)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
      %{status: _, body: body} when is_binary(body) -> {:error, %{"error" => [body]}}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def update_banner(discord_user_id, build_uid, params) do
    case post!("/users/#{discord_user_id}/builds/#{build_uid}/banner", %{photo: params}) do
      %{status: 202, body: body} -> {:ok, parse_build(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
      %{status: _, body: body} when is_binary(body) -> {:error, %{"error" => [body]}}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def parse_user(attrs) do
    user_changeset(%User{}, attrs)
    |> Ecto.Changeset.cast_embed(:builds, with: &build_changeset/2)
    |> Ecto.Changeset.apply_changes()
  end

  def parse_build(attrs) do
    build_changeset(%Build{}, attrs)
    |> Ecto.Changeset.apply_changes()
  end

  def parse_photo(attrs) do
    photo_changeset(%Build.Photo{}, attrs)
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
    |> Ecto.Changeset.cast(attrs, [:discord_user_id, :instagram_handle, :prefered_unit, :hand_size])
    |> Ecto.Changeset.cast_embed(:featured_build, with: &build_changeset/2)
  end

  def build_changeset(build, attrs) do
    Ecto.Changeset.cast(build, attrs, [
      :banner_photo_id,
      :color,
      :description,
      :make,
      :model,
      :tires,
      :uid,
      :wheels,
      :year,
      :mileage,
      :vin
    ])
    |> Ecto.Changeset.cast_embed(:photos, with: &photo_changeset/2)
    |> put_photo_url(:banner_photo_url, :banner_photo_id)
  end
end
