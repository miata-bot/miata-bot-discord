defmodule MiataBotDiscord.CarinfoListener.Util do
  alias Nostrum.Struct.Embed
  import Nostrum.Api
  require Logger

  def do_update_build(author, params) do
    with {:ok, user} <- fetch_or_create_user(author),
         {:ok, featured_build} <- fetch_or_create_featured_build(user),
         {:ok, build} <- update_build(author, featured_build, params),
         embed <- embed_from_info(author, user, build) do
      {:ok, embed}
    else
      {:error, reason} ->
        embed =
          %Embed{}
          |> Embed.put_title("Error updating info")
          |> Embed.put_color(0xFF0000)
          |> put_errors(reason)

        {:ok, embed}

      unknown ->
        raise "unknown error #{inspect(unknown)}"
    end
  end

  def put_errors(embed, error) do
    Enum.reduce(error, embed, fn {key, msg}, embed ->
      Embed.put_field(embed, to_string(key), Enum.join(msg, " "))
    end)
  end

  def fetch_or_create_featured_build(%MiataBot.Partpicker.User{featured_build: nil} = user) do
    create_featured_build(user.discord_user_id, %{})
  end

  def fetch_or_create_featured_build(%MiataBot.Partpicker.User{} = user) do
    {:ok, user.featured_build}
  end

  def create_featured_build(discord_user_id, attrs) do
    case MiataBot.Partpicker.create_build(discord_user_id, attrs) do
      {:ok, build} ->
        MiataBot.Partpicker.update_user_featured_build(discord_user_id, build.uid)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def fetch_or_create_user(%Nostrum.Struct.Guild.Member{user_id: user_id}) do
    fetch_or_create_user(user_id)
  end

  def fetch_or_create_user(%{user_id: user_id}) do
    fetch_or_create_user(user_id)
  end

  def fetch_or_create_user(author_id) do
    case MiataBot.Partpicker.user(author_id) do
      {:ok, user} -> {:ok, user}
      {:error, %{"error" => ["not found"]}} -> create_user(author_id)
      {:error, reason} -> {:error, reason}
    end
  end

  def create_user(%{user_id: user_id}) do
    create_user(user_id)
  end

  def create_user(author_id) do
    MiataBot.Partpicker.create_user(author_id)
  end

  def update_build(%{user_id: user_id}, info, params) do
    update_build(user_id, info, params)
  end

  def update_build(author_id, info, params) do
    MiataBot.Partpicker.update_build(author_id, info.uid, params)
  end

  @doc """
  params:
      %{attachment_url: attachment.url, discord_user_id: author.id}
  """
  def update_image(%{user_id: user_id}, build, params) do
    update_image(user_id, build, params)
  end

  def update_image(author_id, build, params) do
    MiataBot.Partpicker.update_banner(author_id, build.uid, params)
  end

  def embed_from_info(%Nostrum.Struct.Guild.Member{user_id: user_id}, user, build) do
    embed_from_info(user_id, user, build)
  end

  def embed_from_info(
        # %Nostrum.Struct.User{} = discord_user,
        user_id,
        %MiataBot.Partpicker.User{} = user,
        %MiataBot.Partpicker.Build{} = build
      ) do
    %Embed{}
    |> Embed.put_title("#{build.year} #{build.make} #{build.model}")
    |> Embed.put_url("https://miatapartpicker.gay/car/#{build.uid}")
    |> Embed.put_description(build.description)
    |> maybe_add_year(build)
    |> maybe_add_color(build)
    |> maybe_add_image(build)
    |> maybe_add_wheels(build)
    |> maybe_add_tires(build)
    |> maybe_add_coilovers(build)
    |> maybe_add_ride_height(build)
    |> maybe_add_mileage(build, user)
    |> maybe_add_vin(build)
    |> maybe_add_hand_size(user)
    |> maybe_add_foot_size(user)
    |> maybe_add_instagram(user)
  end

  def maybe_add_year(embed, %{year: nil}), do: embed
  def maybe_add_year(embed, %{year: year}), do: Embed.put_field(embed, "Year", year, true)

  def maybe_add_image(embed, %{banner_photo_url: nil}), do: embed
  def maybe_add_image(embed, %{banner_photo_url: url}), do: Embed.put_image(embed, url)

  def maybe_add_wheels(embed, %{wheels: nil}), do: embed

  def maybe_add_wheels(embed, %{wheels: wheels}),
    do: Embed.put_field(embed, "Wheels", wheels, true)

  def maybe_add_tires(embed, %{tires: nil}), do: embed
  def maybe_add_tires(embed, %{tires: tires}), do: Embed.put_field(embed, "Tires", tires, true)

  def maybe_add_coilovers(embed, %{coilovers: nil}), do: embed

  def maybe_add_coilovers(embed, %{coilovers: coilovers}),
    do: Embed.put_field(embed, "Coilovers", coilovers, true)

  def maybe_add_ride_height(embed, %{ride_height: nil}), do: embed

  def maybe_add_ride_height(embed, %{ride_height: ride_height}),
    do: Embed.put_field(embed, "Ride Height", "#{to_string(ride_height)} height units", true)

  def maybe_add_vin(embed, %{vin: nil}), do: embed
  def maybe_add_vin(embed, %{vin: vin}), do: Embed.put_field(embed, "VIN", vin, true)

  def maybe_add_mileage(embed, %{mileage: nil}), do: embed

  def maybe_add_mileage(embed, %{mileage: mileage}, %{prefered_unit: :miles}),
    do: Embed.put_field(embed, "Mileage", "#{mileage} miles", true)

  def maybe_add_mileage(embed, %{mileage: mileage}, %{prefered_unit: :km}),
    do: Embed.put_field(embed, "Mileage", "#{mileage} km", true)

  def maybe_add_instagram(embed, %{instagram_handle: nil}), do: embed

  def maybe_add_instagram(embed, %{instagram_handle: "@" <> handle}),
    do: Embed.put_field(embed, "Instagram", "https://instagram.com/#{handle}")

  def maybe_add_instagram(embed, %{instagram_handle: handle}),
    do: Embed.put_field(embed, "Instagram", "https://instagram.com/#{handle}")

  def maybe_add_hand_size(embed, %{hand_size: nil}), do: embed

  def maybe_add_hand_size(embed, %{hand_size: inches}),
    do:
      embed
      |> Embed.put_field("Hand Size", "#{inches} inches")

  def maybe_add_foot_size(embed, %{foot_size: nil}), do: embed

  def maybe_add_foot_size(embed, %{foot_size: inches}),
    do:
      embed
      |> Embed.put_field("Foot Size", "#{inches} inches")

  def maybe_add_color(embed, %{color: nil}), do: embed

  def maybe_add_color(embed, %{color: color}) do
    embed = Embed.put_field(embed, "Color", color, true)
    color = String.downcase(color)

    cond do
      String.contains?(color, "red") -> Embed.put_color(embed, 0xD11A06)
      String.contains?(color, "green") -> Embed.put_color(embed, 0x00FF00)
      String.contains?(color, "blue") -> Embed.put_color(embed, 0x0000FF)
      String.contains?(color, "white") -> Embed.put_color(embed, 0xFFFFFF)
      String.contains?(color, "black") -> Embed.put_color(embed, 0x000000)
      true -> embed
    end
  end

  def get_discord_user(data, _guild_id) do
    case Snowflake.cast(to_string(data)) do
      {:ok, snowflake} ->
        Logger.info("using snowflake: #{to_string(data)}")
        get_user(snowflake)

      :error ->
        {:error, "unknown data: #{inspect(data)}"}
    end
  end

  # don't display buttons if there's only one build
  def init_carinfo_component(_, %MiataBot.Partpicker.User{builds: [_], featured_build: %{}}) do
    {:ok, nil}
  end

  def init_carinfo_component(discord_user_id, _) do
    components = %{
      type: 1,
      components: [
        %{type: 2, label: "Previous", style: 1, custom_id: "carinfo.previous.#{discord_user_id}"},
        %{type: 2, label: "Next", style: 1, custom_id: "carinfo.next.#{discord_user_id}"}
      ]
    }

    {:ok, components}
  end

  # def previous_carinfo_embed(nil) do
  #   {:error, "couldn't find info in cache"}
  # end

  def previous_carinfo_embed({discord_user, user, index}) do
    case Enum.at(user.builds, index - 1) do
      %MiataBot.Partpicker.Build{} = build ->
        embed = embed_from_info(discord_user, user, build)

        {:ok, embed, {discord_user, user, index - 1}}

      nil ->
        embed = embed_from_info(discord_user, user, user.featured_build)
        {:ok, embed, {discord_user, user, 0}}
    end
  end

  def next_carinfo_embed({discord_user, user, index}) do
    if index >= Enum.count(user.builds) - 1 do
      embed = embed_from_info(discord_user, user, user.featured_build)
      {:ok, embed, {discord_user, user, 0}}
    else
      case Enum.at(user.builds, index + 1) do
        %MiataBot.Partpicker.Build{} = build ->
          embed = embed_from_info(discord_user, user, build)

          {:ok, embed, {discord_user, user, index - 1}}

        nil ->
          embed = embed_from_info(discord_user, user, user.featured_build)
          {:ok, embed, {discord_user, user, 0}}
      end
    end
  end

  def carinfo_update_page_response(embed, discord_user_id) do
    response = %{
      type: 7,
      data: %{
        embeds: [embed],
        components: [
          %{
            type: 1,
            components: [
              %{type: 2, label: "Previous", style: 1, custom_id: "carinfo.previous.#{discord_user_id}"},
              %{type: 2, label: "Next", style: 1, custom_id: "carinfo.next.#{discord_user_id}"}
            ]
          }
        ]
      }
    }

    {:ok, response}
  end

  def assemble_carinfo_get_response(embed, nil) do
    response = %{type: 4, data: %{embeds: [embed]}}
    {:ok, response}
  end

  def assemble_carinfo_get_response(embed, component) do
    response = %{type: 4, data: %{embeds: [embed], components: [component]}}
    {:ok, response}
  end
end
