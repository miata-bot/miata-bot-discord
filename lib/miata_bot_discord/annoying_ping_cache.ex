defmodule MiataBotDiscord.AnnoyingPingCache do
  use GenServer

  def ping?(pinger, pingee) do
    GenServer.call(__MODULE__, {:ping?, pinger, pingee})
  end

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:ping?, pinger, pingee}, _from, state) do
    case state[{pinger, pingee}] do
      nil ->
        {:reply, true, Map.put(state, {pinger, pingee}, DateTime.utc_now())}

      _ ->
        {:reply, false, Map.put(state, {pinger, pingee}, DateTime.utc_now())}
    end
  end
end
