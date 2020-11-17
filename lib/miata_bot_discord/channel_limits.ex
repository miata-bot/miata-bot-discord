defmodule MiataBotDiscord.ChannelLimits do
  use GenServer
  alias Nostrum.Struct.Message

  def start_link([channel_id]) do
    GenServer.start_link(__MODULE__, channel_id, name: name(channel_id))
  end

  def start_link(channel_id) do
    GenServer.start_link(__MODULE__, channel_id, name: name(channel_id))
  end

  def name(channel_id), do: Module.concat(__MODULE__, to_string(channel_id))

  def process_activity(%Message{channel_id: channel_id} = message) do
    GenServer.cast(name(channel_id), {:process_activity, message})
  end

  def init(channel_id) do
    {:ok, %{channel_id: channel_id, limits: %{}}}
  end

  def handle_cast({:process_activity, %{author: %{id: author_id} = author} = message}, state) do
    old_limits_for_user = state.limits[author_id] || []
    new_limits_for_user = [message | old_limits_for_user]
    new_limits = Map.put(state.limits, author_id, new_limits_for_user)

    if length(new_limits_for_user) >= 5 do
      offtopic_channel = %Nostrum.Struct.Channel{id: 322_162_421_156_282_369}

      Nostrum.Api.create_message!(
        state.channel_id,
        "#{author} due to the increase in offtopic messages from miata fans in general miata, the amount of messages they can send are limited. Please move to #{
          offtopic_channel
        }"
      )

      Nostrum.Api.delete_message(message)
    end

    {:noreply, %{state | limits: new_limits}}
  end
end
