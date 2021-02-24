defmodule MiataBotDiscord.Guild.MemesChannelConsumer do
  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.{EventDispatcher, Responder}
  alias MiataBotDiscord.Guild.CopyPastaWorker

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

        _, {actions, state} ->
          {actions, state}
      end)

    {:noreply, actions, state}
  end

  def handle_message(
        %Message{content: "$copypasta add " <> content, member: member} = message,
        {actions, state}
      ) do
    new_actions =
      if state.config.admin_role_id in member.roles do
        content =
          maybe_get_message_content_from_snowflake(content, message.channel_id, state.guild.id)

        MiataBot.Repo.insert!(%MiataBot.CopyPasta{
          content: content,
          created_by_discord_id: message.author.id
        })

        [
          {:create_message!,
           [message.channel_id, "Added new copypasta. Your contribution is greatly appreciated."]}
        ]
      else
        [{:create_message!, [message.channel_id, "You aren't an admin you frikin dongle"]}]
      end

    {actions ++ new_actions, state}
  end

  def handle_message(
        %Message{channel_id: channel} = message,
        {actions, %{config: %{memes_channel_id: channel}} = state}
      ) do
    new_actions = CopyPastaWorker.activity(message)
    {actions ++ new_actions, state}
  end

  def handle_message(%Message{}, {actions, state}) do
    {actions, state}
  end

  defp maybe_get_message_content_from_snowflake(content, channel_id, guild_id) do
    with {:ok, message_id} <- Snowflake.cast(content),
         {:ok, %{content: content}} <-
           Responder.execute_action(guild_id, {:get_channel_message, [channel_id, message_id]}) do
      content
    else
      _ ->
        content
    end
  end
end
