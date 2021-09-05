defmodule MiataBot.Partpicker.GatewaySupervisor do
  @moduledoc false
  use Supervisor

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init(_) do
    children = [
      {MiataBot.Partpicker.Gateway, MiataBot.Partpicker.gateway_uri()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
