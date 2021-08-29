defmodule MiataBotDiscord.AutoreplyListener.Bang do
  alias Nostrum.Struct.Message

  defmacro bang(match, reply) do
    quote location: :keep do
      def handle_message_create(%Message{content: unquote(match) <> _} = message, state) do
        create_message!(message.channel_id, unquote(reply))
        {:noreply, state}
      end
    end
  end
end
