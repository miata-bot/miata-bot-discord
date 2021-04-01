defmodule MiataBotIRC.ConnectionHandler do
  defstruct host: "chat.freenode.net",
            port: 6667,
            pass: "",
            nick: "MiataBot",
            user: "MiataBot",
            name: "MiataBot",
            client: nil

  require Logger
  use GenServer

  def start_link([client, opts]) do
    state = struct!(__MODULE__, opts)
    GenServer.start_link(__MODULE__, [%{state | client: client}])
  end

  def init([state]) do
    ExIRC.Client.add_handler(state.client, self())
    ExIRC.Client.connect!(state.client, state.host, state.port)
    {:ok, state}
  end

  def handle_info({:connected, server, port}, state) do
    Logger.info("Connected to #{server}:#{port}")
    ExIRC.Client.logon(state.client, state.pass, state.nick, state.user, state.name)
    {:noreply, state}
  end

  def handle_info(
        {:received, message,
         %ExIRC.SenderInfo{
           nick: nick,
           user: _user
         }, _channel},
        state
      ) do
    MiataBotDiscord.api().create_message!(643_947_340_453_118_019, """
    [#{nick}] #{message}
    """)

    {:noreply, state}
  end

  def handle_info(
        {:joined, channel,
         %ExIRC.SenderInfo{
           nick: nick,
           user: _user
         }},
        state
      ) do
    MiataBotDiscord.api().create_message!(643_947_340_453_118_019, """
    \* *#{nick}* joined #{channel}
    """)

    {:noreply, state}
  end

  def handle_info(
        {:quit, reason,
         %ExIRC.SenderInfo{
           nick: _nick,
           user: user
         }},
        state
      ) do
    MiataBotDiscord.api().create_message!(643_947_340_453_118_019, """
    \* *#{user}* quit (#{reason})
    """)

    {:noreply, state}
  end

  # def handle_info({:names_list, channel, _list}, state) do
  #   {:noreply, state}
  # end

  # Catch-all for messages you don't care about
  def handle_info(msg, state) do
    IO.inspect(msg, label: "unexpected message")
    {:noreply, state}
  end
end
