defmodule MiataBotDiscord.Guild.MuteConsumer do
  @moduledoc """
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
    table = :ets.new(:"#{__MODULE__}.#{guild.id}", [])

    {:producer_consumer,
     %{
       table: table,
       guild: guild,
       current_user: current_user,
       config: config,
       muted: %{}
     }, subscribe_to: [via(guild, EventDispatcher)]}
  end

  @impl GenStage
  def handle_info({:mute_expired, channel_id, author_id}, state) do
    muted = Map.delete(state.muted, author_id)

    {:noreply,
     [{:create_message!, [channel_id, "#{%Nostrum.Struct.User{id: author_id}} is now unmuted"]}],
     %{state | muted: muted}}
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

        {:MESSAGE_REACTION_ADD, reaction}, {actions, state} ->
          # Logger.info("reaction #{inspect(reaction)}")
          handle_reaction(reaction, {actions, state})

        {:MESSAGE_REACTION_REMOVE, reaction}, {actions, state} ->
          handle_reaction_remove(reaction, {actions, state})

        _, {actions, state} ->
          {actions, state}
      end)

    {:noreply, actions, state}
  end

  def handle_message(message, {actions, state}) do
    case state.muted[message.author.id] do
      {_, timer} when is_reference(timer) ->
        {actions ++ [{:delete_message!, [message]}], state}

      _ ->
        true = :ets.insert(state.table, {message.id, message.author.id})
        new_actions = maybe_auto_react(message)
        {actions ++ new_actions, state}
    end
  end

  def handle_reaction(
        %{
          channel_id: channel_id,
          emoji: %{name: "🔇"},
          member: %{user: %{id: _}},
          message_id: message_id,
          user_id: _
        },
        {actions, state}
      ) do
    case :ets.lookup(state.table, message_id) do
      [{^message_id, author_id}] ->
        Logger.info("handle_mute")
        state = increment(state, author_id)
        handle_mute(author_id, channel_id, {actions, state})

      unk ->
        Logger.warn("#{inspect(unk)}")
        {actions, state}
    end
  end

  def handle_reaction(
        %{
          channel_id: channel_id,
          emoji: %{name: "🔈"},
          message_id: message_id,
          user_id: _
        },
        {actions, state}
      ) do
    case :ets.lookup(state.table, message_id) do
      [{^message_id, author_id}] ->
        Logger.info("handle_unmute")
        handle_unmute(author_id, channel_id, {actions, state})

      unk ->
        Logger.warn("unmute: #{inspect(unk)}")
        {actions, state}
    end
  end

  def handle_reaction(reaction, {actions, state}) do
    Logger.info("unknown reaction add: #{inspect(reaction)}")
    {actions, state}
  end

  def handle_reaction_remove(
        %{
          channel_id: _,
          emoji: %{id: nil, name: "🔇"},
          guild_id: _,
          message_id: message_id,
          user_id: _
        },
        {actions, state}
      ) do
    case :ets.lookup(state.table, message_id) do
      [{^message_id, author_id}] ->
        state = decrement(state, author_id)
        {actions, state}

      _unk ->
        {actions, state}
    end
  end

  def handle_reaction_remove(_reaction, {actions, state}) do
    # Logger.info("unknown remove reaction #{inspect(reaction)}")
    {actions, state}
  end

  def increment(state, author_id) do
    muted =
      Map.update(state.muted, author_id, {1, nil}, fn {count, timer} ->
        Logger.info("ing #{author_id} #{count + 1}")
        {count + 1, timer}
      end)

    %{state | muted: muted}
  end

  def decrement(state, author_id) do
    muted =
      Map.update(state.muted, author_id, {1, nil}, fn {count, timer} ->
        Logger.info("dec #{author_id} #{count - 1}")
        {count - 1, timer}
      end)

    %{state | muted: muted}
  end

  def handle_mute(author_id, channel_id, {actions, state}) do
    case state.muted[author_id] do
      {3, _} ->
        Logger.info("Muting #{author_id} in #{channel_id}")
        # user is now muted
        actions =
          actions ++
            [
              {:create_message!,
               [channel_id, "#{%Nostrum.Struct.User{id: author_id}} has been muted for 3 minutes"]}
            ]

        # ms = 300_000
        # ms = 5000
        ms = 60000
        # ms = 180_000
        mute(author_id, channel_id, self(), ms, {actions, state})

      {count, _} when count >= 5 ->
        Logger.info("Extending mute for #{author_id} in #{channel_id}")
        mute(author_id, channel_id, self(), 30000, {actions, state})

      {count, _} ->
        Logger.info("Not muting #{author_id} (for now) #{count}")
        {actions, state}
    end
  end

  def mute(author_id, channel_id, pid, ms, {actions, state}) do
    muted =
      Map.update(state.muted, author_id, {5, nil}, fn
        {count, nil} ->
          timer = Process.send_after(pid, {:mute_expired, channel_id, author_id}, ms)
          {count, timer}

        {count, timer} ->
          remaining = Process.read_timer(timer) || 0

          new_timer =
            Process.send_after(pid, {:mute_expired, channel_id, author_id}, remaining + ms)

          {count, new_timer}
      end)

    {actions, %{state | muted: muted}}
  end

  def handle_unmute(author_id, channel_id, {actions, state}) do
    case state.muted[author_id] do
      {_, nil} ->
        {actions, state}

      {_, timer} ->
        Process.cancel_timer(timer)
        muted = Map.delete(state.muted, author_id)

        {actions ++
           [
             {:message_create!,
              [channel_id, "#{%Nostrum.Struct.User{id: author_id}} has been unmuted"]}
           ], %{state | muted: muted}}
    end
  end

  def maybe_auto_react(%{content: nil}), do: []

  def maybe_auto_react(message) do
    cond do
      String.match?(message.content, ~r/porsche/) -> [auto_react_action(message)]
      String.match?(message.content, ~r/porch/) -> [auto_react_action(message)]
      String.match?(message.content, ~r/proletariat/) -> [auto_react_action(message)]
      String.match?(message.content, ~r/poorsche/) -> [auto_react_action(message)]
      true ->
        []
    end
  end

  def auto_react_action(%{id: message_id, channel_id: channel_id}) do
    {:create_reaction, [channel_id, message_id, %Nostrum.Struct.Emoji{name: "🔇"}]}
  end
end
