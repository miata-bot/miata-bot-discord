defmodule MiataBotDiscord.MemesChannelListener do
  use Quarrel.Listener
  require Logger

  alias MiataBot.{Repo, CopyPasta}
  import Ecto.Query

  @timeout 60_000
  @max 5

  @impl GenServer
  def init(state) do
    {:ok,
     state
     |> assign(:message_count, 0)
     |> assign(:timer, nil)}
  end

  @impl Quarrel.Listener
  def handle_message_create(
        %Message{channel_id: channel_id},
        %{config: %{memes_channel_id: channel_id}} = state
      ) do
    if state.assigns.timer, do: Process.cancel_timer(state.assigns.timer)

    case state.assigns.message_count do
      count when count >= @max ->
        create_message!(channel_id, content: load_copy_pasta(), tts: true)

        {:noreply,
         state
         |> assign(:message_count, 0)
         |> assign(:timer, Process.send_after(self(), :timeout, @timeout))}

      count ->
        {:noreply,
         state
         |> assign(:message_count, count + 1)
         |> assign(:timer, Process.send_after(self(), :timeout, @timeout))}
    end
  end

  def handle_message_create(_, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:timeout, state) do
    {:noreply,
     state
     |> assign(:timer, nil)
     |> assign(:message_count, 0)}
  end

  defp load_copy_pasta() do
    Repo.one(from cp in CopyPasta, order_by: fragment("RANDOM()"), limit: 1, select: cp.content) ||
      "Someone was too lazy to add any copypastas"
  end
end
