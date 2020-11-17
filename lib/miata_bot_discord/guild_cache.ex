defmodule MiataBotDiscord.GuildCache do
  use GenServer

  def cache(guild) do
    GenServer.cast(__MODULE__, {:cache, guild})
  end

  def list_guilds do
    :ets.tab2list(:guilds)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    table = :ets.new(:guilds, [:named_table, :public, :set])
    {:ok, %{table: table}}
  end

  @impl GenServer
  def handle_cast({:cache, guild}, %{table: table} = state) do
    true = :ets.insert(table, {guild.id, guild})
    {:noreply, state}
  end
end
