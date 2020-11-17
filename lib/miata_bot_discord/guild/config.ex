defmodule MiataBotDiscord.Guild.Config do
  use Ecto.Schema
  import Ecto.Changeset

  schema "guild_configs" do
    field :guild_id, Snowflake
    field :verification_channel_id, Snowflake
    field :memes_channel_id, Snowflake
    field :general_channel_id, Snowflake
    field :offtopic_channel_id, Snowflake
    field :miata_fan_role_id, Snowflake
    field :looking_for_miata_role_id, Snowflake
    field :bot_spam_channel_id, Snowflake
  end

  @required_fields [
    :guild_id,
    :verification_channel_id,
    :memes_channel_id,
    :general_channel_id,
    :offtopic_channel_id,
    :miata_fan_role_id,
    :looking_for_miata_role_id,
    :bot_spam_channel_id
  ]

  @doc false
  def changeset(guild_config, attrs \\ %{}) do
    guild_config
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
