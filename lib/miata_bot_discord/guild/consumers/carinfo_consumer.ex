defmodule MiataBotDiscord.Guild.CarinfoConsumer do
  @moduledoc """
  Processes commands from users
  """

  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.{EventDispatcher, Responder}
  alias Nostrum.Struct.{Embed, Interaction, Message, Message.Attachment}
  import MiataBotDiscord.Guild.CarinfoConsumer.Util

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
          channel_id: _channel_id,
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
      {:ok, embed} ->
        response = %{type: 4, data: %{embeds: [embed]}}
        {actions ++ [{:create_interaction_response, [iaction, response]}], state}

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
      {:ok, embed} ->
        response = %{type: 4, data: %{embeds: [embed]}}
        {actions ++ [{:create_interaction_response, [iaction, response]}], state}

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
        "coilovers",
        "ride_height"
      ])

    with {:ok, build_embed} <- do_update_build(member.user, car_params),
         {:ok, _} <- MiataBot.Partpicker.update_user(member.user.id, user_params) do
      response = %{type: 4, data: %{embeds: [build_embed]}}
      {actions ++ [{:create_interaction_response, [iaction, response]}], state}
    else
      {:ok, embed} ->
        response = %{type: 4, data: %{embeds: [embed]}}
        {actions ++ [{:create_interaction_response, [iaction, response]}], state}

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

  def handle_interaction(_interaction, {actions, state}) do
    # Logger.warn("unhandled interaction: #{inspect(interaction)}")
    {actions, state}
  end
end
