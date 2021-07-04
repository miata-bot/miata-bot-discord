defmodule MiataBotDiscord.Guild.CarinfoConsumer do
  @moduledoc """
  Processes commands from users
  """

  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.{EventDispatcher, Responder}
  alias Nostrum.Struct.{Embed, Interaction, Message}

  @doc false
  def start_link({guild, config, current_user}) do
    GenStage.start_link(__MODULE__, {guild, config, current_user}, name: via(guild, __MODULE__))
  end

  @impl GenStage
  def init({guild, config, current_user}) do
    {:producer_consumer, %{guild: guild, current_user: current_user, config: config},
     subscribe_to: [via(guild, EventDispatcher)]}
  end

  @impl GenStage
  def handle_events(events, _from, %{current_user: %{id: current_user_id}} = state) do
    {actions, state} =
      Enum.reduce(events, {[], state}, fn
        # Ignore messages from self
        {:MESSAGE_CREATE, %{author: %{id: author_id}}}, {actions, state}
        when author_id == current_user_id ->
          {actions, state}

        {:GUILD_MEMBER_ADD, new}, {actions, state} ->
          handle_member_add(new, {actions, state})

        {:MESSAGE_CREATE, message}, {actions, state} ->
          handle_message(message, {actions, state})

        {:INTERACTION_CREATE, interaction}, {actions, state} ->
          handle_interaction(interaction, {actions, state})

        _, {actions, state} ->
          {actions, state}
      end)

    {:noreply, actions, state}
  end

  def handle_member_add(new, {actions, state}) do
    _ = fetch_or_create_featured_build(new.user)
    {actions, state}
  end

  def handle_message(
        %Message{channel_id: channel_id, content: "$carinfo" <> _},
        {actions, state}
      ) do
    content = """
    The carinfo command is now a discord interaction.
    All commands are now prefixed with `/`
    """

    {actions ++ [{:create_message!, [channel_id, content]}], state}
  end

  def handle_message(_message, {actions, state}) do
    {actions, state}
  end

  def handle_interaction(
        iaction = %Interaction{
          guild_id: guild_id,
          channel_id: channel_id,
          data: %{
            name: "carinfo",
            options: [
              %{name: "get", type: 1, options: [%{name: "user", type: 6, value: user_discord_id}]}
            ]
          }
        },
        {actions, state}
      ) do
    with {:ok, discord_user} <- get_discord_user(user_discord_id, guild_id),
         {:ok, user} <- fetch_or_create_user(discord_user),
         {:ok, build} <- fetch_or_create_featured_build(user),
         embed <- embed_from_info(discord_user, user, build) do
      response = %{type: 4, data: %{embeds: [embed]}}
      {actions ++ [{:create_interaction_response, [iaction, response]}], state}
    else
      error ->
        response = %{type: 4, data: %{content: "Unknown error happened: #{inspect(error)}"}}

        {actions ++
           [
             {:create_interaction_response, [iaction, response]}
           ], state}
    end
  end

  def handle_interaction(
        iaction = %Interaction{
          channel_id: channel_id,
          member: member,
          data: %{
            name: "carinfo",
            options: [%{name: "get", type: 1}]
          }
        },
        {actions, state}
      ) do
    with {:ok, user} <- fetch_or_create_user(member),
         {:ok, build} <- fetch_or_create_featured_build(user) do
      embed = embed_from_info(member, user, build)
      response = %{type: 4, data: %{embeds: [embed]}}

      {actions ++
         [
           {:create_interaction_response, [iaction, response]}
         ], state}
    else
      error ->
        response = %{type: 4, data: %{content: "Unknown error happened: #{inspect(error)}"}}

        {actions ++
           [
             {:create_interaction_response, [iaction, response]}
           ], state}
    end
  end

  # update 07-03-21: too lazy after interactions update. Maybe no one will notice.

  def handle_interaction(
        iaction = %Interaction{
          member: member,
          data: %{
            name: "carinfo",
            options: [%{name: "update", options: options}]
          }
        },
        {actions, state}
      ) do
    {car_params, user_params} =
      Map.new(options, fn %{name: name, value: value} -> {name, value} end)
      |> Map.split([
        "year",
        "vin",
        "mileage",
        "color",
        "title",
        "description",
        "wheels",
        "tires",
        "coilovers"
      ])

    with {:ok, build_embed} <- do_update_build(member.user, car_params),
         {:ok, _} <- MiataBot.Partpicker.update_user(member.user.id, user_params) do
      response = %{type: 4, data: %{embeds: [build_embed]}}
      {actions ++ [{:create_interaction_response, [iaction, response]}], state}
    else
      error ->
        response = %{type: 4, data: %{content: "Something went wrong: #{inspect(error)}"}}
        {actions ++ [{:create_interaction_response, [iaction, response]}], state}
    end
  end

  def handle_interaction(
        iaction = %Interaction{
          data: %{
            name: "carinfo",
            options: [%{name: "update"}]
          }
        },
        {actions, state}
      ) do
    response = %{type: 4, data: %{content: "No options supplied."}}
    {actions ++ [{:create_interaction_response, [iaction, response]}], state}
  end

  def handle_interaction(interaction, {actions, state}) do
    Logger.warn("unhandled interaction: #{inspect(interaction)}")
    {actions, state}
  end

  defp do_update_build(author, params) do
    with {:ok, user} <- fetch_or_create_user(author),
         {:ok, build} <- fetch_or_create_featured_build(user),
         {:ok, build} <- update_build(author, build, params),
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

  def fetch_or_create_featured_build(%MiataBot.Partpicker.User{featured_build: build}) do
    {:ok, build}
  end

  def create_featured_build(discord_user_id, attrs) do
    case MiataBot.Partpicker.create_build(discord_user_id, attrs) do
      {:ok, build} ->
        case MiataBot.Partpicker.update_user_featured_build(discord_user_id, build.uid) do
          {:ok, %{featured_build: build}} -> {:ok, build}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def fetch_or_create_user(%Nostrum.Struct.Guild.Member{user: user}) do
    fetch_or_create_user(user)
  end

  def fetch_or_create_user(author) do
    case MiataBot.Partpicker.user(author.id) do
      {:ok, user} -> {:ok, user}
      {:error, %{"error" => ["not found"]}} -> create_user(author)
      {:error, reason} -> {:error, reason}
    end
  end

  def create_user(author) do
    MiataBot.Partpicker.create_user(author.id)
  end

  def update_build(author, info, params) do
    MiataBot.Partpicker.update_build(author.id, info.uid, params)
  end

  def update_image(author, info, params) do
    MiataBot.Partpicker.update_banner(author.id, info.uid, params)
  end

  def embed_from_info(%Nostrum.Struct.Guild.Member{user: discord_user}, user, build) do
    embed_from_info(discord_user, user, build)
  end

  def embed_from_info(
        %Nostrum.Struct.User{} = discord_user,
        %MiataBot.Partpicker.User{} = user,
        %MiataBot.Partpicker.Build{} = build
      ) do
    %Embed{}
    |> Embed.put_title("#{discord_user.username}'s Miata")
    |> Embed.put_url("https://miatapartpicker.gay/car/#{build.uid}")
    |> Embed.put_description(build.description)
    |> maybe_add_year(build)
    |> maybe_add_color(build)
    |> maybe_add_image(build)
    |> maybe_add_wheels(build)
    |> maybe_add_tires(build)
    |> maybe_add_coilovers(build)
    |> maybe_add_mileage(build, user)
    |> maybe_add_vin(build)
    |> maybe_add_hand_size(user)
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

  defp get_discord_user(data, guild_id) do
    case Snowflake.cast(to_string(data)) do
      {:ok, snowflake} ->
        Logger.info("using snowflake: #{to_string(data)}")
        Responder.execute_action(guild_id, {:get_user, [snowflake]})

      :error ->
        {:error, "unknown data: #{inspect(data)}"}
    end
  end
end
