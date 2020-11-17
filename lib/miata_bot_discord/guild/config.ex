defmodule MiataBotDiscord.Guild.Config do
  use Ecto.Schema
  import Ecto.Changeset

  schema "guild_configs" do
    field :guild_id, Snowflake
    field :verification_channel_id, Snowflake
    field :memes_channel_id, Snowflake
  end

  @doc false
  def changeset(guild_config, attrs \\ %{}) do
    guild_config
    |> cast(attrs, [:guild_id, :verification_channel_id, :memes_channel_id])
    |> validate_required([:guild_id, :verification_channel_id, :memes_channel_id])
  end
end
