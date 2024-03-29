defmodule MiataBot.Partpicker do
  use Tesla

  def base_url,
    do:
      Application.get_env(:miata_bot, __MODULE__)[:base_url] ||
        "https://partpicker.fly.dev/api"

  def asset_url,
    do:
      Application.get_env(:miata_bot, __MODULE__)[:asset_url] ||
        "https://partpicker.fly.dev/media/"

  def api_token do
    Application.get_env(:miata_bot, __MODULE__)[:api_token]
  end

  def client do
    middleware = [
      {Tesla.Middleware.BaseUrl, base_url()},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"authorization", "Bearer " <> api_token()}]}
    ]

    Tesla.client(middleware)
  end

  def gateway_uri do
    gateway_url =
      Application.get_env(:miata_bot, __MODULE__)[:gateway_url] ||
        "wss://partpicker.fly.dev/api/gateway"

    URI.parse(gateway_url)
    |> Map.put(:userinfo, "#{@api_token}")
  end

  defmodule Photo do
    use Ecto.Schema
    @primary_key {:uuid, :binary_id, [autogenerate: false]}
    embedded_schema do
      field :filename, :string
      field :url, :string
    end
  end

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
      field :ride_height, :float

      embeds_many :photos, Photo

      field :tires, :string
      field :wheels, :string
      field :year, :integer
      field :coilovers, :string
    end
  end

  defmodule Card do
    use Ecto.Schema
    @primary_key {:id, :string, [autogenerate: false]}
    embedded_schema do
      field :asset_url, :string
    end
  end

  defmodule TradeRequest do
    use Ecto.Schema

    embedded_schema do
      field :sender, Snowflake
      field :receiver, Snowflake
      field :status, :string
      embeds_one :offer, Card
      embeds_one :trade, Card
    end
  end

  defmodule User do
    use Ecto.Schema
    @primary_key {:discord_user_id, Snowflake, [autogenerate: false]}
    embedded_schema do
      field :instagram_handle, :string
      field :prefered_unit, Ecto.Enum, values: [:km, :miles]
      field :hand_size, :float
      field :foot_size, :float
      field :steam_id, :string
      field :preferred_timezone, :string
      field :builds, {:array, :string}
      field :featured_build, :string
      # embeds_many :builds, Build
      # embeds_many :cards, Card
      # embeds_one :featured_build, Build
    end
  end

  def user(discord_user_id) do
    user =
      case get!(client(), "/users/#{discord_user_id}") do
        %{status: 200, body: body} -> {:ok, parse_user(body)}
        %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
      end

    with {:ok, user} <- user,
         {:ok, builds} <- builds(discord_user_id),
         {:ok, featured_build} <- maybe_get_featured_build(user) do
      {:ok, %{user | builds: builds, featured_build: featured_build}}
    end
  end

  def maybe_get_featured_build(%{featured_build: nil}), do: {:ok, nil}

  def maybe_get_featured_build(%{discord_user_id: discord_user_id, featured_build: build_id}) do
    build(discord_user_id, build_id)
  end

  def create_user(discord_user_id) do
    case post!(client(), "/users/", %{user: %{discord_user_id: discord_user_id}}) do
      %{status: 201, body: body} -> {:ok, parse_user(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
    end
  end

  def update_user_featured_build(discord_user_id, featured_build_uid) do
    attrs = %{featured_build_id: featured_build_uid}

    case put!(client(), "/users/#{discord_user_id}/featured_build", attrs) do
      %{status: 202, body: body} -> {:ok, parse_user(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
    end
  end

  def update_user(discord_user_id, params) do
    case put!(client(), "/users/#{discord_user_id}", %{user: params}) do
      %{status: 202, body: body} -> {:ok, parse_user(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
      %{status: _, body: body} when is_binary(body) -> {:error, %{"error" => [body]}}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def create_build(discord_user_id, params) do
    case post!(client(), "/users/#{discord_user_id}/builds/", %{build: params}) do
      %{status: 201, body: body} -> {:ok, parse_build(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
      %{status: _, body: body} when is_binary(body) -> {:error, %{"error" => [body]}}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def update_build(discord_user_id, build_uid, params) do
    case put!(client(), "/users/#{discord_user_id}/builds/#{build_uid}", %{build: params}) do
      %{status: 202, body: body} -> {:ok, parse_build(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
      %{status: _, body: body} when is_binary(body) -> {:error, %{"error" => [body]}}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def builds(discord_user_id) do
    case get!(client(), "/users/#{discord_user_id}/builds/") do
      %{status: 200, body: body} -> {:ok, Enum.map(body, &parse_build/1)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
      %{status: _, body: body} when is_binary(body) -> {:error, %{"error" => [body]}}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def build(discord_user_id, build_uid) do
    case get!(client(), "/users/#{discord_user_id}/builds/#{build_uid}") do
      %{status: 200, body: body} when is_list(body) -> {:ok, Enum.map(body, &parse_build/1)}
      %{status: 200, body: body} -> {:ok, parse_build(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
      %{status: _, body: body} when is_binary(body) -> {:error, %{"error" => [body]}}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def generate_random_card() do
    case get!(client(), "/cards/generate_random_offer") do
      %{status: 202, body: body} -> {:ok, parse_card(body)}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def claim_card(card, discord_user_id) do
    case post!(client(), "/cards/claim_random_offer", %{card_id: card.id, user_id: discord_user_id}) do
      %{status: 201, body: body} -> {:ok, parse_card(body)}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def update_banner(discord_user_id, build_uid, params) do
    case post!(client(), "/users/#{discord_user_id}/builds/#{build_uid}/banner", %{photo: params}) do
      %{status: 202, body: body} -> {:ok, parse_build(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
      %{status: _, body: body} when is_binary(body) -> {:error, %{"error" => [body]}}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def random_photo(discord_user_ids) do
    case post!(client(), "/photos/random", %{"discord_user_ids" => discord_user_ids}) do
      %{status: 200, body: body} -> {:ok, parse_photo(body)}
      %{status: 404, body: _body} -> {:error, %{"error" => ["not found"]}}
      %{status: _, body: body} when is_binary(body) -> {:error, %{"error" => [body]}}
      %{status: _, body: %{"errors" => errors}} -> {:error, errors}
    end
  end

  def parse_user(attrs) do
    user_changeset(%User{}, attrs)
    # |> Ecto.Changeset.cast_embed(:builds, with: &build_changeset/2)
    # |> Ecto.Changeset.cast_embed(:cards, with: &card_changeset/2)
    |> Ecto.Changeset.apply_changes()
  end

  def parse_build(attrs) do
    build_changeset(%Build{}, attrs)
    |> Ecto.Changeset.apply_changes()
  end

  def parse_photo(attrs) do
    photo_changeset(%Photo{}, attrs)
    |> Ecto.Changeset.apply_changes()
  end

  def parse_card(attrs) do
    card_changeset(%Card{}, attrs)
    |> Ecto.Changeset.apply_changes()
  end

  def parse_trade_request(attrs) do
    trade_request_changeset(%TradeRequest{}, attrs)
    |> Ecto.Changeset.apply_changes()
  end

  def photo_changeset(photo, attrs) do
    photo
    |> Ecto.Changeset.cast(attrs, [:filename, :uuid])
    |> put_photo_url(:url, :uuid)
  end

  def put_photo_url(changeset, field, uuid_field) do
    if uuid = Ecto.Changeset.get_field(changeset, uuid_field) do
      Ecto.Changeset.put_change(changeset, field, "#{asset_url()}/#{uuid}")
    else
      changeset
    end
  end

  def user_changeset(user, attrs) do
    user
    |> Ecto.Changeset.cast(attrs, [
      :discord_user_id,
      :instagram_handle,
      :prefered_unit,
      :hand_size,
      :foot_size,
      :steam_id,
      :preferred_timezone,
      :builds,
      :featured_build
    ])

    # |> Ecto.Changeset.cast_embed(:featured_build, with: &build_changeset/2)
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
      :vin,
      :coilovers,
      :ride_height
    ])
    |> Ecto.Changeset.cast_embed(:photos, with: &photo_changeset/2)
    |> put_photo_url(:banner_photo_url, :banner_photo_id)
  end

  def card_changeset(card, attrs) do
    Ecto.Changeset.cast(card, attrs, [
      :id,
      :asset_url
    ])
  end

  def trade_request_changeset(trade_request, attrs) do
    Ecto.Changeset.cast(trade_request, attrs, [
      :sender,
      :receiver,
      :status
    ])
    |> Ecto.Changeset.cast_embed(:offer, with: &card_changeset/2)
    |> Ecto.Changeset.cast_embed(:trade, with: &card_changeset/2)
  end
end
