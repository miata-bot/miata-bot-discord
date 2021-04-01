defmodule MiataBotIRC do
  use Supervisor

  alias MiataBotIRC.{ConnectionHandler, LoginHandler}

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_) do
    config = Application.get_env(:miata_bot, __MODULE__, [])
    {:ok, client} = ExIRC.start_link!()

    children = [
      # Define workers and child supervisors to be supervised
      {ConnectionHandler, [client, config]},
      # here's where we specify the channels to join:
      {LoginHandler, [client, ["#miata"]]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExampleApplication.Supervisor]
    Supervisor.init(children, opts)
  end
end
