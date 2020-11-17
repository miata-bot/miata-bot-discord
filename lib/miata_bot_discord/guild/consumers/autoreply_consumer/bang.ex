defmodule MiataBotDiscord.Guild.AutoreplyConsumer.Bang do
  alias Nostrum.Struct.Message

  defmacro bang(match, reply) do
    quote location: :keep do
      def handle_message(%Message{content: unquote(match) <> _} = message, {actions, state}) do
        {actions ++ [{:create_message!, [message.channel_id, unquote(reply)]}], state}
      end
    end
  end
end
