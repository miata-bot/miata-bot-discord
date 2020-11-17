defmodule MiataBotDiscord.Guild.EventDispatcher do
  @moduledoc false
  use GenStage
  import MiataBotDiscord.Guild.Registry, only: [via: 2]

  @doc "Broadcast an event to all consumers"
  def dispatch(guild, event) do
    GenStage.cast(via(guild, __MODULE__), {:dispatch, event})
  end

  @doc false
  def start_link(guild) do
    GenStage.start_link(__MODULE__, guild, name: via(guild, __MODULE__))
  end

  @impl GenStage
  def init(_args) do
    {:producer, {:queue.new(), 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  @impl GenStage
  def handle_cast({:dispatch, event}, {queue, pending_demand}) do
    queue = :queue.in(event, queue)
    dispatch_events(queue, pending_demand, [])
  end

  @impl GenStage
  def handle_demand(incoming_demand, {queue, pending_demand}) do
    dispatch_events(queue, incoming_demand + pending_demand, [])
  end

  defp dispatch_events(queue, 0, events) do
    {:noreply, Enum.reverse(events), {queue, 0}}
  end

  defp dispatch_events(queue, demand, events) do
    case :queue.out(queue) do
      {{:value, event}, queue} ->
        dispatch_events(queue, demand - 1, [event | events])

      {:empty, queue} ->
        {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end
