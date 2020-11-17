defmodule MiataBotDiscord.FakeAPI do
  def create_message!(channel_id, content) do
    {:ok, %Nostrum.Struct.Message{channel_id: channel_id, content: content}}
  end

  def get_channel!(channel_id) do
    %Nostrum.Struct.Channel{
      application_id: nil,
      bitrate: nil,
      guild_id: 643_947_339_895_013_416,
      icon: nil,
      id: channel_id,
      last_message_id: nil,
      last_pin_timestamp: nil,
      name: "deleteme",
      nsfw: false,
      owner_id: nil,
      parent_id: 644_744_557_166_329_857,
      permission_overwrites: [],
      position: 53,
      recipients: nil,
      topic: nil,
      type: 0,
      user_limit: nil
    }
  end
end
