defmodule MiataBotDiscord.AutoreplyListener.Bang do
  alias Nostrum.Struct.Message
  alias Nostrum.Struct.User
  
  defmacro bang(match, reply) do
    quote location: :keep do
      def handle_message_create(%Message{author: %User{bot: nil}, content: unquote(match) <> _} = message, state) do
        create_message!(message.channel_id, unquote(reply))
        {:noreply, state}
      end
    end
  end
end
