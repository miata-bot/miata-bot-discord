defmodule MiataBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      AnnoyingPingCache,
      PastebinRandomizer,
      # Start the Ecto repository
      MiataBot.Repo,
      MiataBot.GuildCache.Supervisor,
      # MiataBot.Discord.Supervisor,
      MiataBot.CopyPastaWorker,
      MiataBot.LookingForMiataWorker,
      # Start the endpoint when the application starts
      MiataBotWeb.Endpoint,
      MiataBotWeb.HerokuTask
      # Starts a worker by calling: MiataBot.Worker.start_link(arg)
      # {MiataBot.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MiataBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MiataBotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
