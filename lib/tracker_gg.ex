defmodule TrackerGG do
  use Tesla
  plug Tesla.Middleware.BaseUrl, "https://public-api.tracker.gg/v2/"
  @api_token Application.get_env(:miata_bot, __MODULE__)[:api_token]

  plug(Tesla.Middleware.Headers, [{"TRN-Api-Key", @api_token}])
  plug(Tesla.Middleware.JSON)

  %{
    "additionalParameters" => nil,
    "avatarUrl" =>
      "https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/38/3866c09ff72d3ce46313a5c96c3669f89f8f3b07_full.jpg",
    "platformId" => 3,
    "platformSlug" => "steam",
    "platformUserHandle" => "PLS_PressY4Pie",
    "platformUserId" => "76561198096242407",
    "platformUserIdentifier" => "76561198096242407",
    "status" => nil
  }

  defmodule PlatformInfo do
    use Ecto.Schema

    embedded_schema do
      field :platformSlug, :string
      field :platformUserHandle, :string
      field :platformUserId, :string
      field :platformUserIdentifier, :string
    end
  end

  defmodule Splitgate.User do
    use Ecto.Schema

    @primary_key {:platformUserId, :string, [autogenerate: false]}
    embedded_schema do
      field :avatarUrl, :string
      field :platformUserHandle, :string
      field :platformUserIdentifier, :string
    end
  end

  defmodule Splitgate.Segment do
    use Ecto.Schema

    embedded_schema do
      field :attributes, :map
      field :metadata, :map
      field :type, :string
      field :stats, :map
    end
  end

  defmodule Splitgate.Profile do
    use Ecto.Schema

    embedded_schema do
      embeds_many :availableSegments, Splitgate.Segment
      field :expiryDate, :utc_datetime
      field :metadata, :map
      embeds_one :platformInfo, PlatformInfo
      embeds_many :segments, Splitgate.Segment
    end
  end

  def user_changeset(user, attrs) do
    Ecto.Changeset.cast(user, attrs, [:avatarUrl, :platformUserHandle, :platformUserId, :platformUserIdentifier])
  end

  def profile_changeset(profile, attrs) do
    profile
    |> Ecto.Changeset.cast(attrs, [:expiryDate, :metadata])
    |> Ecto.Changeset.cast_embed(:availableSegments, with: &segment_changeset/2)
    |> Ecto.Changeset.cast_embed(:segments, with: &segment_changeset/2)
    |> Ecto.Changeset.cast_embed(:platformInfo, with: &platform_info_changeset/2)
  end

  def segment_changeset(segment, attrs) do
    segment
    |> Ecto.Changeset.cast(attrs, [:attributes, :metadata, :type, :stats])
  end

  def platform_info_changeset(platform_info, attrs) do
    platform_info
    |> Ecto.Changeset.cast(attrs, [
      :platformSlug,
      :platformUserHandle,
      :platformUserId,
      :platformUserIdentifier
    ])
  end

  def splitgate_profile(platform \\ "steam", platformUserIdentifier) do
    case get("/splitgate/standard/profile/#{platform}/#{platformUserIdentifier}") do
      {:ok, %{status: 200, body: %{"data" => data}}} ->
        {:ok, parse_splitgate_profile(data)}

      error ->
        error
    end
  end

  def splitgate_user_search(platform \\ "steam", query) do
    query = URI.encode_query(%{platform: platform, query: query})

    case get("/splitgate/standard/search?#{query}") do
      {:ok, %{status: 200, body: %{"data" => data}}} ->
        {:ok, Enum.map(data, &parse_splitgate_user/1)}

      error ->
        error
    end
  end

  def parse_splitgate_user(attrs) do
    user_changeset(%Splitgate.User{}, attrs)
    |> Ecto.Changeset.apply_changes()
  end

  def parse_splitgate_profile(attrs) do
    profile_changeset(%Splitgate.Profile{}, attrs)
    |> Ecto.Changeset.apply_changes()
  end

  def get_splitgate_lifetime_overview(profile) do
    overview =
      profile.segments
      |> Enum.find(fn
        %{metadata: %{"name" => "Lifetime Overview"}} -> true
        _ -> nil
      end)

    case overview do
      nil -> {:error, "could not find overview for that user"}
      overview -> {:ok, overview}
    end
  end
end
