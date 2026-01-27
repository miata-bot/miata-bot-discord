defmodule MiataBotDiscord.MemesChannelListener do
  use Quarrel.Listener
  use Bitwise
  require Logger

  alias MiataBot.{Repo, CopyPasta}
  import Ecto.Query

  @timeout 600_000
  @max 3

  @admin_role 643_958_189_460_553_729

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
        create_message!(channel_id, content: load_copy_pasta())

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

  def handle_interaction_create(
        iaction = %Interaction{
          data: %{
            name: "pasta",
            options: [
              %{name: "random", type: 1, options: []}
            ]
          }
        },
        state
      ) do
    response = %{
      type: 4,
      data: %{
        content: "#{Repo.one(from cp in CopyPasta, order_by: fragment("RANDOM()"), limit: 1, select: cp.content)}"
      }
    }

    create_interaction_response(iaction, response)

    {:noreply, state}
  end

  def handle_interaction_create(
        iaction = %Interaction{
          member: %{
            user_id: id,
            roles: roles
          },
          data: %{
            name: "pasta",
            options: [
              %{
                name: "modify",
                type: 1,
                options: [%{name: "add", type: 3, value: copypasta}]
              }
            ]
          }
        },
        state
      ) do
    if Enum.member?(roles, @admin_role) or id == 276436248263000065 do
      case MiataBot.Repo.insert(%MiataBot.CopyPasta{content: copypasta, created_by_discord_id: id}) do
        {:ok, _} ->
          response = %{type: 4, data: %{content: "successfully added pasta! \"#{copypasta}\""}}
          create_interaction_response(iaction, response)

        {:error, reason} ->
          response = %{type: 4, data: %{content: "failed to add copy pasta: #{inspect(reason)}"}}
          create_interaction_response(iaction, response)
      end
    else
      response = %{type: 4, data: %{content: "<:sorrybuddy:1137121335731028049>"}}
      create_interaction_response(iaction, response)
    end

    {:noreply, state}
  end

  def handle_interaction_create(interaction, state) do
    # Logger.warn("unhandled interaction: #{inspect(interaction)}")
    {:noreply, state}
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
