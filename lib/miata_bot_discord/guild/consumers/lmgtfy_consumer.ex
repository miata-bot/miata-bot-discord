defmodule MiataBotDiscord.Guild.LMGTFYConcumer do
  @moduledoc """
  Processes commands from users
  """

  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.EventDispatcher

  alias Nostrum.Struct.{Message, Embed}

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
        %Message{content: "!google" <> search, channel_id: channel_id},
        {actions, state}
      ) do
    q = URI.encode_query(%{q: search, iee: 1})
    lmgtfy = "https://lmgtfy.com/?#{q}"

    embed =
      Embed.put_url(%Embed{}, lmgtfy)
      |> Embed.put_title("let me google that for you")

    {actions ++ [{:create_message!, [channel_id, [embed: embed]]}], state}
  end

  def handle_message(%Message{}, {actions, state}) do
    {actions, state}
  end
end
