defmodule MiataBot.GuildCache do
  require Logger
  use GenServer

  def upsert_guild(%{id: guild_id} = guild) do
    GenServer.call(table_name(guild_id), {:upsert_guild, guild})
  end

  def get_guild(%{id: guild_id}) do
    get_guild(guild_id)
  end

  def get_guild(guild_id) when is_binary(guild_id) do
    get_guild(String.to_integer(guild_id))
  end

  def get_guild(guild_id) when is_integer(guild_id) do
    GenServer.call(table_name(guild_id), :get_guild)
  end

  def upsert_guild_member(guild_id, member_id, member) do
    GenServer.call(table_name(guild_id), {:upsert_guild_member, member_id, member})
  end

  def get_guild_member(guild_id, member_id) do
    GenServer.call(table_name(guild_id), {:get_guild_member, member_id})
  end

  def list_guild_members(guild_id) do
    GenServer.call(table_name(guild_id), :list_guild_members)
  end

  def start_link(%{id: guild_id} = guild) do
    GenServer.start_link(__MODULE__, guild, name: table_name(guild_id))
  end

  def init(guild) do
    table_name = table_name(guild.id)
    ^table_name = :ets.new(table_name, [:named_table, :ordered_set, :public])
    {:ok, %{guild: guild, table: table_name}}
  end

  def handle_call({:upsert_guild, guild}, _from, state) do
    {:reply, :ok, %{state | guild: guild}}
  end

  def handle_call(:get_guild, _from, %{guild: guild} = state) do
    {:reply, guild, state}
  end

  def handle_call({:upsert_guild_member, member_id, member}, _from, %{table: table} = state) do
    reply = :ets.insert(table, {member_id, member})
    {:reply, reply, state}
  end

  def handle_call(:list_guild_members, _from, %{table: table} = state) do
    reply = :ets.match_object(table, {:"$0", :"$1"})
    {:reply, reply, state}
  end

  def handle_call({:get_guild_member, member_id}, _from, %{table: table} = state) do
    case :ets.match_object(table, {member_id, :"$0"}) do
      [{_id, member}] ->
        {:reply, member, state}

      [] ->
        {:reply, nil, state}
    end
  end

  def table_name(guild_id), do: String.to_atom(to_string(guild_id))
end
