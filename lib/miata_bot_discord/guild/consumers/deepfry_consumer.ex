defmodule MiataBotDiscord.Guild.DeepfryConsumer do
  @moduledoc """
  Processes commands from users
  """

  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.EventDispatcher
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
        %Message{
          referenced_message: %Message{attachments: [attachment | _]},
          content: "!deepfry" <> _
        } = message,
        {actions, state}
      ) do
    action = generate_action(message, attachment)

    {actions ++ [action], state}
  end

  def handle_message(
        %Message{
          attachments: [attachment | _],
          content: "!deepfry" <> _
        } = message,
        {actions, state}
      ) do
    action = generate_action(message, attachment)

    {actions ++ [action], state}
  end

  def handle_message(
        %Message{
          embeds: [%Nostrum.Struct.Embed{image: embed_image} | _],
          content: "!deepfry" <> _
        } = message,
        {actions, state}
      ) do
    action = generate_action(message, embed_image)

    {actions ++ [action], state}
  end

  def handle_message(
        %Message{
          referenced_message: %Message{attachments: [attachment | _]},
          channel_id: 826_548_854_945_611_786
        } = message,
        {actions, state}
      ) do
    action = generate_action(message, attachment)

    {actions ++ [action], state}
  end

  def handle_message(
        %Message{
          attachments: [attachment | _],
          channel_id: 826_548_854_945_611_786
        } = message,
        {actions, state}
      ) do
    action = generate_action(message, attachment)

    {actions ++ [action], state}
  end

  def handle_message(
        %Message{
          embeds: [%Nostrum.Struct.Embed{image: embed_image} | _],
          channel_id: 826_548_854_945_611_786
        } = message,
        {actions, state}
      ) do
    action = generate_action(message, embed_image)

    {actions ++ [action], state}
  end

  def handle_message(_message, {actions, state}) do
    {actions, state}
  end

  def generate_action(message, %Nostrum.Struct.Message.Attachment{} = attachment) do
    %{body: image} = Tesla.get!(attachment.url)
    File.write!("/tmp/#{attachment.filename}", image)

    script = Application.app_dir(:miata_bot, ["/priv/bin/fry.sh"])
    {_, 0} = System.cmd(script, ["/tmp/#{attachment.filename}", "/tmp/fried.jpg"])

    {:create_message!,
     [
       message.channel_id,
       [
         content: "#{message.author}",
         file: "/tmp/fried.jpg"
       ]
     ]}
  end

  def generate_action(message, %Nostrum.Struct.Embed.Image{url: url}) do
    %{body: image} = Tesla.get!(url)
    File.write!("/tmp/image0", image)

    script = Application.app_dir(:miata_bot, ["/priv/bin/fry.sh"])
    {_, 0} = System.cmd(script, ["/tmp/image0", "/tmp/fried.jpg"])

    {:create_message!,
     [
       message.channel_id,
       [
         content: "#{message.author}",
         file: "/tmp/fried.jpg"
       ]
     ]}
  end
end
