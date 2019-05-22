defmodule MiataBot.Snowflake do
  @behaviour Ecto.Type
  require Nostrum.Snowflake

  def type, do: :string

  def dump(term) do
    {:ok, Nostrum.Snowflake.dump(term)}
  end

  def cast(term) do
    Nostrum.Snowflake.cast(term)
  end

  def load(term) do
    Nostrum.Snowflake.cast(term)
  end
end
