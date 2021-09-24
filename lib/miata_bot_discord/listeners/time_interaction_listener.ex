defmodule MiataBotDiscord.TimeInteractionListener do
  @moduledoc """
  used for looking up localtime for a user
  """

  use Quarrel.Listener
  require Logger

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl Quarrel.Listener
  def handle_interaction_create(
        %Interaction{data: %{name: "time", options: [%{name: "user", value: discord_user_id}]}} = iaction,
        state
      ) do
    with {:ok, %MiataBot.Partpicker.User{preferred_timezone: tz}} <- MiataBot.Partpicker.user(discord_user_id),
         {:ok, shifted} <- DateTime.shift_zone(DateTime.utc_now(), tz) do
      response = %{type: 4, data: %{content: "#{shifted}"}}
      create_interaction_response(iaction, response)
    else
      {:error, :time_zone_not_found} ->
        response = %{type: 4, data: %{content: "that user has not configured their timezone. maybe ping them about it"}}
        create_interaction_response(iaction, response)

      error ->
        response = %{type: 4, data: %{content: "error getting time for user: #{inspect(error)}"}}
        create_interaction_response(iaction, response)
    end

    {:noreply, state}
  end

  def handle_interaction_create(_, state) do
    {:noreply, state}
  end
end
