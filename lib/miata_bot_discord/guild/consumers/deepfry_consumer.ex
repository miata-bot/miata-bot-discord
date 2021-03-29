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

  def handle_message(_message, {actions, state}) do
    {actions, state}
  end

  def generate_action(message, %Nostrum.Struct.Message.Attachment{} = attachment) do
    %{body: image} = Tesla.get!(attachment.url)
    File.write!("/tmp/#{attachment.filename}", image)

    mog_image =
      Mogrify.open("/tmp/#{attachment.filename}")
      |> Mogrify.format("jpg")
      |> Mogrify.quality("1%")
      |> Mogrify.save()

    mog_image =
      Mogrify.open(mog_image.path)
      |> Mogrify.resize("50%")
      |> Mogrify.format("png")
      |> Mogrify.save()

    mog_image =
      Mogrify.open(mog_image.path)
      |> Mogrify.format("jpg")
      |> Mogrify.resize("200%")
      |> Mogrify.quality("1%")
      |> Mogrify.save()

    {:create_message!,
     [
       message.channel_id,
       [
         content: "#{message.author}",
         file: %{body: File.read!(mog_image.path), name: "deepfry.jpg"}
       ]
     ]}
  end
end
