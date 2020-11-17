defmodule MiataBotDiscord.Guild.BootmsgConsumer do
  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.EventDispatcher

  @app_version Mix.Project.config()[:version]
  @app_commit Mix.Project.config()[:commit]

  @doc false
  def start_link({guild, config, current_user}) do
    GenStage.start_link(__MODULE__, {guild, config, current_user}, name: via(guild, __MODULE__))
  end

  @impl GenStage
  def init({guild, config, current_user}) do
    send(self(), :bootmsg)

    {:producer_consumer, %{guild: guild, current_user: current_user, config: config},
     subscribe_to: [via(guild, EventDispatcher)]}
  end

  @impl GenStage
  def handle_events(events, _from, %{current_user: %{id: current_user_id}} = state) do
    {actions, state} =
      Enum.reduce(events, {[], state}, fn
        # Ignore messages from self
        {:MESSAGE_CREATE, %{author: %{id: author_id}}}, {actions, state}
        when author_id == current_user_id ->
          {actions, state}

        _, {actions, state} ->
          {actions, state}
      end)

    {:noreply, actions, state}
  end

  @impl GenStage
  def handle_info(:bootmsg, state) do
    channel_id = state.config.bot_spam_channel_id || state.guild.system_channel_id

    content = """
    MiataBot booting up
    Version: #{@app_version}
    Commit: #{@app_commit}
    """

    actions = [{:create_message!, [channel_id, content]}]
    {:noreply, actions, state}
  end
end
