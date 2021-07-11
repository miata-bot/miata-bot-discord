defmodule MiataBotDiscord.Guild.Carinfo.AttachmentConsumer do
  @moduledoc """
  Handles the attachment feature for carinfo
  """

  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.EventDispatcher
  alias MiataBotDiscord.Guild.Carinfo.AttachmentCache
  alias Nostrum.Struct.{Embed, Interaction, Message, Message.Attachment}
  import MiataBotDiscord.Guild.CarinfoConsumer.Util

  @doc false
  def start_link({guild, config, current_user}) do
    GenStage.start_link(__MODULE__, {guild, config, current_user}, name: via(guild, __MODULE__))
  end

  @impl GenStage
  def init({guild, config, current_user}) do
    state = %{guild: guild, current_user: current_user, config: config}
    {:producer_consumer, state, subscribe_to: [via(guild, EventDispatcher)]}
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

        {:INTERACTION_CREATE, interaction}, {actions, state} ->
          handle_interaction(interaction, {actions, state})

        _, {actions, state} ->
          {actions, state}
      end)

    {:noreply, actions, state}
  end

  def handle_message(
        %Message{channel_id: channel_id, attachments: [attachment | _]} = message,
        {actions, %{config: %{carinfo_channel_id: channel_id}} = state}
      ) do
    Logger.info("Caching attachment: #{inspect(attachment)}")
    AttachmentCache.cache_attachment(state.guild, message.author.id, state.guild)
    {actions, state}
  end

  def handle_message(_message, {actions, state}) do
    {actions, state}
  end

  def handle_interaction(
        iaction = %Interaction{
          guild_id: _guild_id,
          channel_id: _channel_id,
          member: member = %{user: %{id: user_discord_id}},
          data: %{
            name: "carinfo",
            options: [
              %{name: "image"}
            ]
          }
        },
        {actions, state}
      ) do
    with {:ok, %Attachment{} = attachment} <- fetch_attachment(user_discord_id, state),
         {:ok, embed} <-
           do_update_image(member.user, %{
             attachment_url: attachment.url,
             discord_user_id: user_discord_id
           }) do
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

  def handle_interaction(_interaction, {actions, state}) do
    # Logger.warn("unhandled interaction: #{inspect(interaction)}")
    {actions, state}
  end

  defp do_update_image(author, params) do
    with {:ok, user} <- fetch_or_create_user(author),
         {:ok, build} <- fetch_or_create_featured_build(user),
         {:ok, build} <- update_image(author, build, params),
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

  defp fetch_attachment(discord_user_id, state) do
    case AttachmentCache.fetch_attachment(state.guild, discord_user_id) do
      %Attachment{} = attachment ->
        {:ok, attachment}

      nil ->
        embed =
          %Embed{}
          |> Embed.put_title("Could not find attachment")
          |> Embed.put_color(0xFF0000)

        {:ok, embed}
    end
  end
end
