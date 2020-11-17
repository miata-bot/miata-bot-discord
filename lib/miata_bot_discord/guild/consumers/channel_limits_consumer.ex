alias MiataBot.ChannelLimits

def handle_event(
      {:MESSAGE_CREATE, %{channel_id: @general_channel_id, member: member} = message, _state}
    ) do
  if @miata_fan_role_id in member.roles do
    Logger.info("doing channel limit for #{inspect(member)}")
    ChannelLimits.process_activity(message)
  end
end

def handle_event(
      {:MESSAGE_UPDATE, %{channel_id: @general_channel_id, member: member} = message},
      _ws_state
    ) do
  if @miata_fan_role_id in member.roles do
    Logger.info("doing channel limit for #{inspect(member)}")
    ChannelLimits.process_activity(message)
  end
end
