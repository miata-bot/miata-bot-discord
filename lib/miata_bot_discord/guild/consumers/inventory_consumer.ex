defmodule MiataBotDiscord.Guild.InventoryConsumer do
  @moduledoc """
  Processes commands from users
  """

  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.EventDispatcher
  alias Nostrum.Struct.{Embed, Interaction}

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

        {:INTERACTION_CREATE, interaction}, {actions, state} ->
          handle_interaction(interaction, {actions, state})

        {:MESSAGE_CREATE, message}, {actions, state} ->
          handle_message(message, {actions, state})

        _, {actions, state} ->
          {actions, state}
      end)

    {:noreply, actions, state}
  end

  def handle_interaction(
        iaction = %Interaction{
          guild_id: _guild_id,
          channel_id: _channel_id,
          data: %{
            name: "inventory",
            options: [
              %{name: "user", type: 6, value: user_id}
            ]
          }
        },
        {actions, state}
      ) do
    {:ok, %{cards: cards, discord_user_id: owner_id}} = MiataBot.Partpicker.user(user_id)

    embeds =
      for %{asset_url: url, id: id} <- cards do
        %Embed{}
        |> Embed.put_field("Owner", "<@#{owner_id}>")
        |> Embed.put_footer(id)
        |> Embed.put_image(url)
      end

    response = %{type: 4, data: %{embeds: embeds}}

    {actions ++
       [
         {:create_interaction_response, [iaction, response]},
         fn response -> Logger.info("interaction complete: #{inspect(response)}") end
       ], state}
  end

  def handle_interaction(
        iaction = %Interaction{
          guild_id: _guild_id,
          channel_id: _channel_id,
          member: %{user: %{id: user_id}},
          data: %{
            name: "inventory"
          }
        },
        {actions, state}
      ) do
    {:ok, %{cards: cards}} = MiataBot.Partpicker.user(user_id)

    embeds =
      for %{asset_url: url, id: id} <- cards do
        %Embed{}
        |> Embed.put_field("ID", id)
        |> Embed.put_image(url)
      end

    response = %{type: 4, data: %{embeds: embeds}}

    {actions ++
       [
         {:create_interaction_response, [iaction, response]},
         fn response -> Logger.info("interaction complete: #{inspect(response)}") end
       ], state}
  end

  def handle_interaction(_interaction, {actions, state}) do
    {actions, state}
  end

  def handle_message(_message, {actions, state}) do
    # Logger.info("message=#{inspect(message)}")
    {actions, state}
  end
end
