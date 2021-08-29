defmodule MiataBotDiscord.ChannelLimitsListener do
  use Quarrel.Listener

  @impl GenServer
  def init(state) do
    {:ok,
     state
     |> assign(:limits, %{})}
  end

  @impl Quarrel.Listener
  def handle_message_create(
        %Message{channel_id: general_channel_id, member: %Member{} = member} = message,
        %{config: %{general_channel_id: general_channel_id, miata_fan_role_id: miata_fan_role_id}} =
          state
      ) do
    if miata_fan_role_id in member.roles do
      handle_miatafan(message, state)
    else
      {:noreply, state}
    end
  end

  def handle_message_create(_, state) do
    {:noreply, state}
  end

  def handle_miatafan(%Message{author: %{id: author_id} = author} = message, state) do
    old_limits_for_user = state.limits[author_id] || []
    new_limits_for_user = [message | old_limits_for_user]
    new_limits = Map.put(state.assigns.limits, author_id, new_limits_for_user)
    offtopic_channel = %Channel{id: state.config.offtopic_channel_id}
    dm_channel = create_dm!(author_id)

    content = """
    #{author} due to the increase in offtopic messages from miata fans in general miata,
    the amount of messages they can send are limited. Please move to #{offtopic_channel}
    """

    cond do
      length(new_limits_for_user) == 6 ->
        create_message!(message.channel_id, content)
        delete_message!(message)

      length(new_limits_for_user) > 6 ->
        create_message!(dm_channel.id, content)
        delete_message!(message)

      true ->
        true
    end

    {:noreply,
     state
     |> assign(:limits, new_limits)}
  end
end
