defmodule MiataBotDiscord.Guild.EvalConsumer do
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

  @impl GenStage
  def handle_info({:tty_data, data}, state) do
    if state.channel_id do
      content = """
      ```elixir
      #{data}
      ```
      """

      actions = [{:create_message!, [state.channel_id, content]}]
      {:noreply, actions, state}
    else
      # reschedule tty data if channel isn't up yet
      send(self(), {:tty_data, data})
      {:noreply, [], state}
    end
  end

  def handle_message(%Message{content: content} = message, {actions, state}) do
    if Regex.match?(~r/eval\s```elixir\s(?<content>[^```]*)(?=```)/, content) do
      handle_eval(
        Regex.named_captures(~r/eval\s```elixir\s(?<content>[^```]*)(?=```)/, content),
        message,
        {actions, state}
      )
    else
      {actions, state}
    end
  end

  def handle_eval(%{"content" => code}, message, {actions, state}) do
    state = start_extty(state, message.channel_id)
    _ = ExTTY.send_text(state.extty, code)
    {actions, state}
  end

  def start_extty(%{extty: nil, channel_id: nil} = state, channel_id) do
    {:ok, tty} = ExTTY.start_link(handler: self())
    %{state | extty: tty, channel_id: channel_id}
  end

  def start_extty(%{extty: _} = state, _) do
    state
  end
end
