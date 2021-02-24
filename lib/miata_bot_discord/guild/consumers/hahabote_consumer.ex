defmodule MiataBotDiscord.Guild.HaHaBoteConsumer do
  @moduledoc """
  Processes commands from users
  """

  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.EventDispatcher

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

  def handle_message(message, {actions, state}) do
    if String.contains?(String.downcase(message.content), "bote") ||
         String.contains?(String.downcase(message.content), "boat") do
      mention = Nostrum.Struct.User.mention(message.author)

      {actions ++
         [
           {:create_message!,
            [
              message.channel_id,
              "#{mention} HAHAHAHAHAAHA BOTE!!!!! https://cdn.discordapp.com/attachments/322080549839699979/798999035138539601/comedygenius.jpg"
            ]}
         ], state}
    else
      {actions, state}
    end
  end
end
