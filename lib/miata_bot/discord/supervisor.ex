defmodule MiataBot.Discord.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    children = [
      {MiataBot.ChannelLimits, 322_080_266_761_797_633},
      {MiataBot.Discord, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
