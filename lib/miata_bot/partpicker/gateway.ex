defmodule MiataBot.Partpicker.Gateway do
  @behaviour :gen_statem
  require Logger

  defmodule Socket do
    defstruct [:gun, :stream, :protocol, :headers, :uri, :events, :handler]
  end

  @ping_timeout 5000
  @reconnect_timeout 1000

  @type socket :: %Socket{
          gun: nil | pid(),
          stream: nil | reference(),
          protocol: nil | iodata(),
          headers: [iodata()],
          uri: URI.t()
        }

  @type action_internal_connect :: {:next_event, :internal, :connect}

  @derive {Inspect, only: [:gun, :stream]}

  def start_link(%{} = uri) do
    :gen_statem.start_link({:local, __MODULE__}, __MODULE__, uri, [])
  end

  def start_link(uri) do
    start_link(URI.parse(uri))
  end

  @impl :gen_statem
  def init(%URI{} = uri) do
    socket = %Socket{uri: uri, events: []}
    # instantly  schedule a connect
    actions = [{:timeout, 0, :connect}]
    {:ok, :disconnected, socket, actions}
  end

  # disconnected state

  def disconnected(:timeout, :connect, socket) do
    connect(socket)
  end

  # def disconnected(:info, {:gun_up, gun, :http}, socket) do

  # end

  def disconnected(
        :info,
        {:DOWN, _monitor, :process, pid, _reason},
        %Socket{handler: {pid, _}} = socket
      ) do
    {:keep_state, %Socket{socket | handler: nil}}
  end

  # connecting state

  def connecting(
        :info,
        {:gun_upgrade, gun, stream, ["websocket"], headers},
        %Socket{gun: gun, stream: stream} = socket
      ) do
    Logger.info("[connecting] connection complete")
    {:next_state, :connected, %Socket{socket | headers: headers}}
  end

  def connecting(:info, {:gun_response, gun, _, _, status, headers}, %Socket{gun: gun} = socket) do
    Logger.error("[connecting] gun_response: #{inspect(status)} #{inspect(headers)}")
    # todo schedule reconnect
    {:next_state, :disconnected, %Socket{socket | gun: nil, stream: nil}}
  end

  def connecting(
        :info,
        {:gun_error, gun, stream, reason},
        %Socket{gun: gun, stream: stream} = socket
      ) do
    Logger.error("[connecting] gun_error: #{inspect(reason)}")
    # todo schedule reconnect
    actions = [{:timeout, @reconnect_timeout, :connect}]
    {:next_state, :disconnected, %Socket{socket | gun: nil, stream: nil}, actions}
  end

  def connecting(
        :info,
        {:DOWN, _monitor, :process, pid, _reason},
        %Socket{handler: {pid, _}} = socket
      ) do
    {:keep_state, %Socket{socket | handler: nil}}
  end

  ## connected state

  def connected(
        :info,
        {:gun_ws, gun, stream, {:text, data}},
        %Socket{
          gun: gun,
          stream: stream
        } = _socket
      ) do
    with {:ok, [type, payload]} <- Jason.decode(data),
         {:ok, payload} <- parse_payload(type, payload) do
      Phoenix.PubSub.broadcast(MiataBot.PubSub, "tcg", [type, payload])
      :keep_state_and_data
    else
      json_error ->
        Logger.error("Failed to decode gateway data: #{inspect(json_error)}")
        :keep_state_and_data
    end
  end

  def connected(:info, {:gun_down, gun, :ws, reason, _, _}, %Socket{gun: gun} = socket) do
    Logger.error("[connected] gun_down: #{inspect(reason)}")
    actions = [{:timeout, @reconnect_timeout, :connect}]
    {:next_state, :disconnected, %Socket{socket | gun: nil, stream: nil}, actions}
  end

  def connected(
        :info,
        {:DOWN, _monitor, :process, pid, _reason},
        %Socket{handler: {pid, _}} = socket
      ) do
    {:keep_state, %Socket{socket | handler: nil}}
  end

  @spec connect(socket) ::
          {:next_state, :connecting, socket} | {:keep_state_and_data, [action_internal_connect]}
  defp connect(socket) do
    Logger.info("gun:open/3")

    connect_opts = %{
      connect_timeout: :timer.minutes(1),
      retry: 10,
      retry_timeout: 100,
      protocols: [:http]
    }

    with {:ok, gun} <-
           :gun.open(to_charlist(socket.uri.host), socket.uri.port || 443, connect_opts),
         {:ok, protocol} <- :gun.await_up(gun),
         stream <- :gun.ws_upgrade(gun, to_charlist(socket.uri.path || '/'), []),
         new_socket <- %Socket{
           socket
           | gun: gun,
             stream: stream,
             protocol: protocol
         } do
      actions = [{:timeout, @ping_timeout, :ping}]
      {:next_state, :connecting, new_socket, actions}
    else
      {:error, reason} ->
        Logger.error("Socket connect error: #{inspect(reason)}")
        actions = [{:timeout, @reconnect_timeout, :connect}]
        {:keep_state_and_data, actions}
    end
  end

  # Genstatm impl

  @impl :gen_statem
  def callback_mode, do: :state_functions

  def child_spec(%URI{} = uri) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [uri]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def parse_payload("CREATE_TRADE_REQUEST", payload), do: {:ok, MiataBot.Partpicker.parse_trade_request(payload)}
  def parse_payload("RANDOM_CARD_EXPIRE", payload), do: {:ok, MiataBot.Partpicker.parse_card(payload)}
end
