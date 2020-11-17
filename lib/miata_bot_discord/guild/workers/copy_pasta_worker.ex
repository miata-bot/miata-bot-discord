defmodule MiataBotDiscord.Guild.CopyPastaWorker do
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBot.{Repo, CopyPasta}
  import Ecto.Query

  @timeout 60_000

  @max 5

  require Logger

  use GenServer

  def start_link({guild, config, current_user}) do
    GenServer.start_link(__MODULE__, {guild, config, current_user}, name: via(guild, __MODULE__))
  end

  def activity(message) do
    GenServer.call(via(message.guild_id, __MODULE__), {:activity, message})
  end

  def init({_guild, _config, _current_user}) do
    {:ok, 0, @timeout}
  end

  def handle_info(:timeout, old) do
    old > 0 && Logger.info("resetting counter from: #{old}")
    {:noreply, 0, @timeout}
  end

  def handle_call({:activity, message}, _from, @max) do
    Logger.info("reached max: #{@max}")
    actions = do_messages(message)

    {:reply, actions, 0, @timeout}
  end

  def handle_call({:activity, _message}, _from, count) do
    Logger.info("incrementing counter: #{count + 1}")
    {:reply, [], count + 1, @timeout}
  end

  defp do_messages(message) do
    copy_pasta =
      Repo.one(from cp in CopyPasta, order_by: fragment("RANDOM()"), limit: 1, select: cp.content)

    [{:create_message!, [message.channel_id, [content: copy_pasta, tts: true]]}]
  end
end
