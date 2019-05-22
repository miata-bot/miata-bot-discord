defmodule MiataBot.Web.Endpoint do
  use Supervisor
  alias MiataBot.Web.{Router, HerokuTask}

  @port Application.get_env(:miata_bot, MiataBot.Web.Endpoint)[:port]
  @url Application.get_env(:miata_bot, MiataBot.Web.Endpoint)[:url]

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Router, options: [port: @port]},
      {HerokuTask, [url: @url]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
