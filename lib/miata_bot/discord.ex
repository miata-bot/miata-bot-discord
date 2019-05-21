defmodule MiataBot.Discord do
  use Nostrum.Consumer
  alias Nostrum.Api

  def start_link do
    Consumer.start_link(__MODULE__, name: __MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, {%{content: "$" <> command} = message}, _state}) do
    handle_command(command, message)
    IO.inspect(message, label: "DISCORD message")
  end

  def handle_event(_), do: :noop

  def handle_command("userinfo", %{channel_id: channel_id, author: %{username: username}}) do
    Api.create_message(channel_id, "username: #{username}")
  end
end