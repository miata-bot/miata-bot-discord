defmodule MiataBotDiscord.Guild.ChannelLimitsConsumer do
  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.EventDispatcher
  alias MiataBotDiscord.ChannelLimits

  alias Nostrum.Struct.Message

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

        {:MESSAGE_CREATE, message}, {actions, state} ->
          handle_message(message, {actions, state})

        {:MESSAGE_UPDATE, message}, {actions, state} ->
          handle_message(message, {actions, state})

        _, {actions, state} ->
          {actions, state}
      end)

    {:noreply, actions, state}
  end

  def handle_message(
        %Message{channel_id: general, member: member} = message,
        {actions, %{config: %{general_channel_id: general, miata_fan_role_id: miata_fan}} = state}
      ) do
    new_actions =
      if miata_fan in member.roles do
        Logger.info("doing channel limit for #{inspect(member)}")
        ChannelLimits.process_activity(message)
      else
        []
      end

    {actions ++ new_actions, state}
  end

  def handle_message(%Message{}, {actions, state}) do
    {actions, state}
  end
end
