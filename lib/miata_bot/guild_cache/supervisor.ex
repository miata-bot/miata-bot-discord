defmodule MiataBot.GuildCache.Supervisor do
  use DynamicSupervisor
  alias MiataBot.GuildCache

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_child(%{id: _guild_id} = guild) do
    DynamicSupervisor.start_child(__MODULE__, {GuildCache, guild})
  end

  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
