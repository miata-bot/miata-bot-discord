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

  defmodule Splitgate.User do
    use Ecto.Schema

    @primary_key {:platformUserId, :string, [autogenerate: false]}
    embedded_schema do
      field :avatarUrl, :string
      field :platformUserHandle, :string
      field :platformUserIdentifier, :string
    end
  end

  def user_changeset(user, attrs) do
    Ecto.Changeset.cast(user, attrs, [:avatarUrl, :platformUserHandle, :platformUserId, :platformUserIdentifier])
  end

  def splitgate_profile(platform \\ "steam", platformUserIdentifier) do
    get("/splitgate/standard/profile/#{platform}/#{platformUserIdentifier}")
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
end
