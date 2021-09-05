defmodule MiataBotDiscord.CarinfoListener do
  require Logger
  use Quarrel.Listener
  import MiataBotDiscord.CarinfoListener.Util

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl Quarrel.Listener
  def handle_guild_member_add(%Member{user: discord_user}, state) do
    with {:ok, user} <- fetch_or_create_user(discord_user),
         {:ok, _build} <- fetch_or_create_featured_build(user) do
      {:noreply, state}
    else
      error ->
        Logger.error("Failed to create build for new member: #{inspect(error)}")
    end
  end

  @impl Quarrel.Listener
  def handle_interaction_create(
        iaction = %Interaction{
          guild_id: guild_id,
          channel_id: _channel_id,
          data: %{
            name: "carinfo",
            options: [
              %{name: "get", type: 1, options: [%{name: "user", type: 6, value: user_discord_id}]}
            ]
          }
        },
        state
      ) do
    with {:ok, discord_user} <- get_discord_user(user_discord_id, guild_id),
         {:ok, user} <- fetch_or_create_user(discord_user),
         {:ok, build} <- fetch_or_create_featured_build(user),
         embed <- embed_from_info(discord_user, user, build) do
      response = %{type: 4, data: %{embeds: [embed]}}
      create_interaction_response(iaction, response)
      {:noreply, state}
    else
      {:ok, embed} ->
        response = %{type: 4, data: %{embeds: [embed]}}
        create_interaction_response(iaction, response)
        {:noreply, state}

      error ->
        response = %{type: 4, data: %{content: "Unknown error happened: #{inspect(error)}"}}
        create_interaction_response(iaction, response)
        {:noreply, state}
    end
  end

  def handle_interaction_create(
        iaction = %Interaction{
          channel_id: _channel_id,
          member: member,
          data: %{
            name: "carinfo",
            options: [%{name: "get", type: 1}]
          }
        },
        state
      ) do
    with {:ok, user} <- fetch_or_create_user(member),
         {:ok, build} <- fetch_or_create_featured_build(user) do
      embed = embed_from_info(member, user, build)
      response = %{type: 4, data: %{embeds: [embed]}}
      create_interaction_response(iaction, response)
      {:noreply, state}
    else
      {:ok, embed} ->
        response = %{type: 4, data: %{embeds: [embed]}}
        create_interaction_response(iaction, response)
        {:noreply, state}

      error ->
        response = %{type: 4, data: %{content: "Unknown error happened: #{inspect(error)}"}}
        create_interaction_response(iaction, response)
        {:noreply, state}
    end
  end

  # update 07-03-21: too lazy after interactions update. Maybe no one will notice.

  def handle_interaction_create(
        iaction = %Interaction{
          member: member,
          data: %{
            name: "carinfo",
            options: [%{name: "update", options: options}]
          }
        },
        state
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
        "coilovers",
        "ride_height"
      ])

    with {:ok, build_embed} <- do_update_build(member.user, car_params),
         {:ok, _} <- MiataBot.Partpicker.update_user(member.user.id, user_params) do
      response = %{type: 4, data: %{embeds: [build_embed]}}
      create_interaction_response(iaction, response)
      {:noreply, state}
    else
      {:ok, embed} ->
        response = %{type: 4, data: %{embeds: [embed]}}
        create_interaction_response(iaction, response)
        {:noreply, state}

      error ->
        response = %{type: 4, data: %{content: "Something went wrong: #{inspect(error)}"}}
        create_interaction_response(iaction, response)
        {:noreply, state}
    end
  end

  def handle_interaction_create(
        iaction = %Interaction{
          data: %{
            name: "carinfo",
            options: [%{name: "update"}]
          }
        },
        state
      ) do
    response = %{type: 4, data: %{content: "No options supplied."}}
    create_interaction_response(iaction, response)
    {:noreply, state}
  end

  def handle_interaction_create(_interaction, state) do
    # Logger.warn("unhandled interaction: #{inspect(interaction)}")
    {:noreply, state}
  end
end
