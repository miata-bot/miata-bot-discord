defmodule MiataBot.Ets do
  use GenServer

  def new(name, opts) do
    GenServer.call(__MODULE__, {:new, name, opts})
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    {:ok, []}
  end

  def handle_call({:new, name, opts}, _from, state) do
    table = :ets.new(name, opts)
    {:reply, table, [table | state]}
  end
end
