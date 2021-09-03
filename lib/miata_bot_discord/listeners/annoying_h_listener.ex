defmodule MiataBotDiscord.AnnoyingHListener do
  use Quarrel.Listener

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl Quarrel.Listener
  def handle_message_create(%Message{content: "h"} = message, state) do
    delete_message!(message)
    {:noreply, state}
  end

  def handle_message_create(_, state) do
    {:noreply, state}
  end
end
