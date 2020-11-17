defmodule MiataBot.CopyPasta do
  use Ecto.Schema
  import Ecto.Changeset

  schema "copy_pastas" do
    field :content, :string, null: false
    field :created_by_discord_id, Snowflake, null: false
    timestamps()
  end

  def changeset(copy_pasta, attrs) do
    copy_pasta
    |> cast(attrs, [:content, :created_by_discord_id])
    |> validate_required([:content, :created_by_discord_id])
  end
end
