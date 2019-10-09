defmodule MiataBot.GuildCache do
  require Logger
  @miata_bot_guilds __MODULE__

  def upsert_guild(%{id: guild_id} = guild) do
    # this really should not be here...
    case :ets.whereis(:miata_bot_guilds) do
      :undefined ->
        Logger.warn("Creating guild cache")

        @miata_bot_guilds =
          MiataBot.Ets.new(@miata_bot_guilds, [:named_table, :ordered_set, :public])

      ref when is_reference(ref) ->
        @miata_bot_guilds
    end

    true = :ets.insert(@miata_bot_guilds, {guild_id, guild})

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

  def list_guilds() do
    :ets.match_object(@miata_bot_guilds, {:"$0", :"$1"})
    |> Enum.map(fn {_, guild} -> guild end)
  end

  def get_guild(guild_id) when is_binary(guild_id) do
    get_guild(String.to_integer(guild_id))
  end

  def get_guild(guild_id) do
    :ets.match_object(@miata_bot_guilds, {:"$0", :"$1"})
    |> Enum.find_value(fn
      {^guild_id, guild} -> guild
      _ -> nil
    end)
  end

  def upsert_guild_member(guild_id, member_id, member) do
    :ets.insert(table_name(guild_id), {member_id, member})
  end

  def list_guild_members(guild_id) do
    :ets.match_object(table_name(guild_id), {:"$0", :"$1"})
  end

  def table_name(guild_id), do: String.to_atom(to_string(guild_id))
end
