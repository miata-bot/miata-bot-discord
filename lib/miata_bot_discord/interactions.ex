defmodule MiataBotDiscord.Interactions do
  def interactions do
    [carinfo(), trade(), inventory(), splitgate(), time()]
  end

  def time do
    %{
      name: "time",
      description: "Get time info for a user",
      options: [
        %{
          name: "user",
          description: "user who'se time to look up",
          type: 6
        }
      ]
    }
  end

  def splitgate do
    %{
      name: "splitgate",
      description: "Get Splitgate stats",
      options: [
        %{
          description: "Get splitgate stats for yourself or another user",
          name: "get",
          options: [%{description: "get info for a user", name: "user", type: 6, required: true}],
          type: 1
        }
      ]
    }
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
            %{description: "update car instagram", name: "instagram", type: 3},
            %{description: "update car image", name: "image", type: 11}
          ],
          type: 1
        },
        %{
          description: "get a random carinfo image (for debugging)",
          name: "random_photo",
          options: [],
          type: 1
        }
      ]
    }
  end

  def trade() do
    %{
      name: "trade",
      description: "Manage trades",
      options: [
        %{
          description: "Offer your own card in exchange for another",
          name: "offer",
          type: 1,
          options: [
            %{description: "offered card id", name: "offer_uuid", type: 3, required: true},
            %{description: "trade card id", name: "trade_uuid", type: 3, required: true}
          ]
        }
      ]
    }
  end

  def inventory() do
    %{
      name: "inventory",
      description: "Manage inventory",
      options: [
        %{description: "See what's in a users inventory", name: "user", type: 6}
      ]
    }
  end
end
