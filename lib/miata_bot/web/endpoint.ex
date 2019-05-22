defmodule MiataBot.Web.Endpoint do
  use Supervisor
  alias MiataBot.Web.{Router, HerokuTask}

  @url Application.get_env(:miata_bot, MiataBot.Web.Endpoint)[:url]

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    port = String.to_integer(System.get_env("PORT"))

    children = [
      {Plug.Cowboy, scheme: :http, plug: Router, options: [port: port]},
      {HerokuTask, [url: @url]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
