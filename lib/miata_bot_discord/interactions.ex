defmodule MiataBotDiscord.Interactions do
  alias MiataBotDiscord.Guild.Config
  alias MiataBot.Repo

  def install_interactions(%Config{guild_id: guild_id} = config) do
    with {:ok, carinfo_command} <-
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
        },
        %{
          description: "Update your own carinfo",
          name: "update",
          options: [
            %{description: "update car year", name: "year", type: 4},
            %{description: "update car vin", name: "vin", type: 3},
            %{description: "update car mileage", name: "mileage", type: 4},
            %{description: "update car color", name: "color", type: 3},
            %{description: "update car title", name: "title", type: 3},
            %{description: "update car description", name: "description", type: 3},
            %{description: "update car wheels", name: "wheels", type: 3},
            %{description: "update car tires", name: "tires", type: 3},
            %{description: "update car coilovers", name: "coilovers", type: 3},
            %{description: "update car instagram", name: "instagram", type: 3}
          ],
          type: 1
        },
        %{
          description: "Update carinfo image",
          name: "image",
          options: [],
          type: 1
        }
      ]
    }
  end
end
