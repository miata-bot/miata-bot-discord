defmodule Snowflake do
  @behaviour Ecto.Type
  require Nostrum.Snowflake

  def type, do: :string

  def dump(str) when is_binary(str) do
    {:ok, str}
  end

  def dump(term) do
    {:ok, Nostrum.Snowflake.dump(term)}
  end

  def cast(term) do
    Nostrum.Snowflake.cast(term)
  end

  def load(term) do
    Nostrum.Snowflake.cast(term)
  end

  def embed_as(_format), do: :self

  def equal?(term, term), do: true
  def equal?(_, _), do: false
end
