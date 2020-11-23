defmodule MiataBotDiscord.Guild.GIFConsumer do
  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.EventDispatcher
  alias Nostrum.Struct.{Message, Message.Attachment, Embed}

  @doc false
  def start_link({guild, config, current_user}) do
    GenStage.start_link(__MODULE__, {guild, config, current_user}, name: via(guild, __MODULE__))
  end

  @impl GenStage
  def init({guild, config, current_user}) do
    {:producer_consumer,
     %{guild: guild, current_user: current_user, config: config, extty: nil, channel_id: nil},
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
        %Message{channel_id: channel},
        {actions, %{config: %{memes_channel_id: channel}}} = state
      ) do
    {actions, state}
  end

  def handle_message(%Message{} = message, {actions, state}) do
    new_actions =
      if contains_annoying_gif?(message) do
        Logger.info("deleting annoying gif message: #{inspect(message)}")

        [
          {:delete_message!, [message]},
          {:message_create!, [message.channel_id, "Please no annoying gifs"]}
        ]
      else
        []
      end

    {actions ++ new_actions, state}
  end

  # Checks embeds for tennor etc gif services
  def contains_annoying_gif?(%Message{embeds: [embed | rest]} = message) do
    contains_annoying_gif?(embed) || contains_annoying_gif?(%Message{message | embeds: rest})
  end

  # checks attachments for gifs
  def contains_annoying_gif?(%Message{attachments: [attachment | rest]} = message) do
    contains_annoying_gif?(attachment) ||
      contains_annoying_gif?(%Message{message | attachments: rest})
  end

  def contains_annoying_gif?(%Attachment{filename: filename}) do
    MIME.from_path(filename) == "image/gif"
  end

  def contains_annoying_gif?(%Embed{type: type}) do
    type in ["gif", "gifv"]
  end

  # checked all embeds and attachments; no gifs found.
  def contains_annoying_gif?(%Message{embeds: [], attachments: []}), do: false
end
