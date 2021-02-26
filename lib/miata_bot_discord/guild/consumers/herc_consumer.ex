defmodule MiataBotDiscord.Guild.HercConsumer do
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
    # just making some random change.....
    if(message.author.id == 226_052_366_745_600_000) do
      # if(message.author.id == 316_741_621_498_511_363) do
      handle_herc(message, actions, state)
    else
      {actions, state}
    end
  end

  def handle_herc(message, actions, state) do
    case process_content(message) do
      {:ok, action} -> {actions ++ [action], state}
      _ -> {actions, state}
    end
  end

  def process_content(%Nostrum.Struct.Message{content: content} = message)
      when is_binary(content) do
    cond do
      String.contains?(String.downcase(content), "slushmatic") -> own_herc_action(message)
      String.contains?(String.downcase(content), "poorsche") -> own_herc_action(message)
      String.contains?(String.downcase(content), "saloon") -> own_herc_action(message)
      String.contains?(String.downcase(content), " boot ") -> own_herc_action(message)
      String.contains?(String.downcase(content), "bonnet") -> own_herc_action(message)
      String.contains?(String.downcase(content), "colour") -> own_herc_action(message)
      String.contains?(String.downcase(content), "ferd") -> own_herc_action(message)
      String.contains?(String.downcase(content), "tyre") -> own_herc_action(message)
      String.contains?(String.downcase(content), "mommytank") -> own_herc_action(message)
      String.contains?(String.downcase(content), "windscreen") -> own_herc_action(message)
      String.contains?(String.downcase(content), "flavour") -> own_herc_action(message)
      String.contains?(String.downcase(content), "bloody") -> own_herc_action(message)
      String.contains?(String.downcase(content), "twat") -> own_herc_action(message)
      String.contains?(String.downcase(content), "winge") -> own_herc_action(message)
      String.contains?(String.downcase(content), "carpark") -> own_herc_action(message)
      String.contains?(String.downcase(content), "theatre") -> own_herc_action(message)
      String.contains?(String.downcase(content), "petrol") -> own_herc_action(message)
      String.contains?(String.downcase(content), "motoring") -> own_herc_action(message)
      String.contains?(String.downcase(content), "bloke") -> own_herc_action(message)
      String.contains?(String.downcase(content), "lad") -> own_herc_action(message)
      String.contains?(String.downcase(content), "bollock") -> own_herc_action(message)
      String.contains?(String.downcase(content), "wanker") -> own_herc_action(message)
      String.contains?(String.downcase(content), "humour") -> own_herc_action(message)
      String.contains?(String.downcase(content), "flavour") -> own_herc_action(message)
      String.contains?(String.downcase(content), "labour") -> own_herc_action(message)
      String.contains?(String.downcase(content), "neighbour") -> own_herc_action(message)
      true -> nil
    end
  end

  def process_content(%Nostrum.Struct.Message{}), do: nil

  def own_herc_action(%Nostrum.Struct.Message{channel_id: channel_id, author: author}) do
    message =
      Enum.random([
        "You live in San Francisco. Stop.",
        "Hear that one on Top Gear?",
        "Hitler would be proud of that one",
        "You kiss your *mum* with that mouth?",
        "https://cdn.discordapp.com/attachments/643947340453118019/814250327019880448/edsy7kdy7yf61.jpg"
      ])

    {:ok, {:create_message!, [channel_id, "#{Nostrum.Struct.User.mention(author)} #{message}"]}}
  end
end
