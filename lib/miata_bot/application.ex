defmodule MiataBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      MiataBot.Repo,
      # Start the endpoint when the application starts
      {Phoenix.PubSub, [name: MiataBot.PubSub, adapter: Phoenix.PubSub.PG2]},
      {MiataBot.Partpicker.Gateway, MiataBot.Partpicker.gateway_uri()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MiataBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
