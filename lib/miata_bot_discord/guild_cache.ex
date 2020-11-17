defmodule MiataBotDiscord.GuildCache do
  use GenServer

  def cache(guild) do
    GenServer.cast(__MODULE__, {:cache, guild})
  end

  def list_guilds do
    :ets.tab2list(:guilds)
  end

  def upsert_guild_member(guild_id, member_id, member) do
    guild =
      case :ets.lookup(:guilds, guild_id) do
        [] -> %Nostrum.Struct.Guild{id: guild_id, members: %{}}
        [{^guild_id, guild}] -> guild
        unknown -> raise "Unexpected result in ets lookup: #{inspect(unknown)}"
      end

    :ets.insert(
      :guilds,
      {guild.id, %{guild | members: Map.put(guild.members, member_id, member)}}
    )
  end

  def list_guild_members(guild_id) do
    case :ets.lookup(:guilds, guild_id) do
      [] -> nil
      [{_, %{members: members}}] -> members
      unknown -> raise "Unexpected result in ets lookup: #{inspect(unknown)}"
    end
  end

  def get_guild_member(guild_id, member_id) do
    guild =
      case :ets.lookup(:guilds, guild_id) do
        [] -> %Nostrum.Struct.Guild{id: guild_id, members: %{}}
        [{^guild_id, guild}] -> guild
        unknown -> raise "Unexpected result in ets lookup: #{inspect(unknown)}"
      end

    guild.members[member_id]
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
