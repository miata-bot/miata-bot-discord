defmodule MiataBotDiscord.CarinfoAttachmentListener.Cache do
  def new(guild_id) do
    :ets.new(Module.concat(__MODULE__, to_string(guild_id)), [
      # :named_table,
      # {:write_concurency, true},
      # {:read_concurency, false},
      :ordered_set,
      :public
    ])
  end

  @spec cache(:ets.table(), integer, integer, map()) :: true
  def cache(table, discord_user_id, message_id, attachment) do
    :ets.insert(table, {discord_user_id, message_id, attachment})
  end

  def fetch(table, discord_user_id) do
    case :ets.lookup(table, discord_user_id) do
      [{_discord_user_id, message_id, attachment}] ->
        true = :ets.delete(table, discord_user_id)
        {message_id, attachment}

      [] ->
        nil
    end
  end
end
