defmodule MiataBotDiscord.Guild.ChannelLimits do
  use GenServer
  alias Nostrum.Struct.Message
  import MiataBotDiscord.Guild.Registry, only: [via: 2]

  def start_link({guild, config, current_user}) do
    GenServer.start_link(__MODULE__, {guild, config, current_user}, name: via(guild, __MODULE__))
  end

  def process_activity(%Message{} = message) do
    GenServer.call(via(message.guild_id, __MODULE__), {:process_activity, message})
  end

  def init({guild, config, current_user}) do
    {:ok, %{guild: guild, config: config, current_user: current_user, limits: %{}}}
  end

  def handle_call(
        {:process_activity, %{author: %{id: author_id} = author} = message},
        _from,
        state
      ) do
    old_limits_for_user = state.limits[author_id] || []
    new_limits_for_user = [message | old_limits_for_user]
    new_limits = Map.put(state.limits, author_id, new_limits_for_user)

    actions =
      if length(new_limits_for_user) >= 5 do
        offtopic_channel = %Nostrum.Struct.Channel{id: state.config.offtopic_channel_id}

        content = """
        #{author} due to the increase in offtopic messages from miata fans in general miata,
        the amount of messages they can send are limited. Please move to #{offtopic_channel}
        """

        [{:create_message!, [message.channel_id, content]}, {:delete_message!, [message]}]
      else
        []
      end

    {:reply, actions, %{state | limits: new_limits}}
  end
end
