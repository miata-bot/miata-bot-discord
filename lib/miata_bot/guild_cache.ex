defmodule MiataBot.GuildCache do
  require Logger

  def upsert_guild(guild_id) do
    table_name = table_name(guild_id)

    case :ets.whereis(table_name) do
      :undefined ->
        Logger.warn("Creating new table: #{inspect(table_name)}")
        ^table_name = MiataBot.Ets.new(table_name, [:named_table, :ordered_set, :public])

      ref when is_reference(ref) ->
        Logger.warn("Table already created: #{inspect(table_name)}")
        table_name
    end
  end

  def upsert_guild_member(guild_id, member_id, member) do
    :ets.insert(table_name(guild_id), {member_id, member})
  end

  def all_guild_members(guild_id) do
    :ets.match_object(table_name(guild_id), {:"$0", :"$1"})
  end

  def table_name(guild_id), do: String.to_atom(to_string(guild_id))
end
