defmodule MiataBotDiscord.CarinfoAttachmentListener do
  require Logger
  use Quarrel.Listener
  alias MiataBotDiscord.CarinfoAttachmentListener.Cache
  import MiataBotDiscord.CarinfoListener.Util

  @impl GenServer
  def init(state) do
    table = Cache.new(state.guild.id)

    {:ok,
     state
     |> assign(:table, table)}
  end

  @impl Quarrel.Listener
  def handle_message_create(
        %Message{id: message_id, channel_id: channel_id, attachments: attachments} = message,
        %{config: %{carinfo_channel_id: channel_id}} = state
      ) do
    case Enum.count(attachments) do
      0 ->
        {:noreply, state}

      _ ->
        attachment = List.last(attachments)
        Logger.info("Caching attachment: #{inspect(attachment)}")

        Cache.cache(state.assigns.table, message.author.id, message_id, attachment)
        create_reaction!(channel_id, message_id, "👀")

        {:noreply, state}
    end
  end

  def handle_message_create(_message, state) do
    {:noreply, state}
  end

  @impl Quarrel.Listener
  def handle_interaction_create(
        iaction = %Interaction{
          guild_id: _guild_id,
          channel_id: channel_id,
          member: member = %{user: %{id: user_discord_id}},
          data: %{
            name: "carinfo",
            options: [
              %{name: "image"}
            ]
          }
        },
        state
      ) do
    Logger.info("Handling attachment interaction")

    with {:ok, {attachment_message_id, %Attachment{} = attachment}} <-
           fetch_attachment(user_discord_id, state),
         {:ok, embed} <-
           do_update_image(member.user, %{
             attachment_url: attachment.url,
             discord_user_id: user_discord_id
           }) do
      Logger.info("Updated carinfo: #{inspect(embed)}")
      response = %{type: 4, data: %{embeds: [embed]}}
      create_interaction_response(iaction, response)
      delete_message(channel_id, attachment_message_id)
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

  def handle_interaction_create(_interaction, state) do
    {:noreply, state}
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
    case Cache.fetch(state.assigns.table, discord_user_id) do
      {message_id, %Attachment{} = attachment} ->
        {:ok, {message_id, attachment}}

      nil ->
        embed =
          %Embed{}
          |> Embed.put_title("Could not find attachment")
          |> Embed.put_description(
            "First upload a photo in the CarInfo Channel, then call this command again."
          )
          |> Embed.put_color(0xFF0000)

        {:ok, embed}
    end
  end
end
