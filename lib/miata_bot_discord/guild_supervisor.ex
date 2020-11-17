defmodule MiataBotDiscord.GuildSupervisor do
  @moduledoc "Interface for starting supervised guilds"

  use DynamicSupervisor

  @doc false
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc "Starts a Guild instance. Should be called from the Event source"
  def start_guild(guild, config, current_user) do
    _ = MiataBotDiscord.GuildCache.cache(guild)
    spec = {MiataBotDiscord.Guild, {guild, config, current_user}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl DynamicSupervisor
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
