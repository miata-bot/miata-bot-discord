defmodule MiataBot.Discord.Util do
  defmacro bang(msg, resp) do
    quote do
      @bangs unquote(msg)
      def handle_event(
            {:MESSAGE_CREATE, %{content: unquote(msg), channel_id: channel_id}, _state}
          ) do
        Nostrum.Api.create_message(
          channel_id,
          unquote(resp)
        )
      end
    end
  end
end
