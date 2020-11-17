defmodule MiataBotDiscord.Supervisor do
  @moduledoc false
  use Supervisor

  # if Mix.env() == :prod && Application.get_env(:nostrum, :token) do
  @dispatch_source MiataBotDiscord.NostrumConsumer
  # else
  #   @dispatch_source MiataBotDiscord.FakeDiscordSource
  # end

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init(_args) do
    children = [
      # Monitors an ETS table for guilds to save data on
      MiataBotDiscord.GuildCache,
      # dynamic supervisor for each guild the bot is in
      MiataBotDiscord.GuildSupervisor,
      # source of discord events
      @dispatch_source
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
