defmodule MiataBotDiscord.Interactions do
  alias MiataBotDiscord.Guild.Config
  alias MiataBot.Repo

  def install_interactions(%Config{guild_id: guild_id} = config) do
    with {:ok, carinfo_command} =
           Nostrum.Api.create_guild_application_command(guild_id, carinfo()),
         {:ok, config} <-
           Repo.update(
             Ecto.Changeset.cast(config, %{interactions: [carinfo_command]}, [:interactions])
           ) do
      {:ok, config}
    end
  end

  def carinfo do
    %{
      name: "carinfo",
      description: "Update and view cars",
      options: [
        %{
          description: "Get carinfo for yourself or another user",
          name: "get",
          options: [%{description: "get info for a user", name: "user", type: 6}],
          type: 1
        }
      ]
    }
  end
end
