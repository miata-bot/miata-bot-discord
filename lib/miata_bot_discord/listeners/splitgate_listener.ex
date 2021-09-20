defmodule MiataBotDiscord.SplitgateListener do
  require Logger
  use Quarrel.Listener

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl Quarrel.Listener
  def handle_interaction_create(
        %Interaction{
          data: %{
            name: "splitgate",
            options: [%{name: "get"}]
          },
          member: %{user: %{id: discord_user_id} = member}
        } = iaction,
        state
      ) do
    with {:ok, %MiataBot.Partpicker.User{steam_id: steam_id}} <- MiataBot.Partpicker.user(discord_user_id),
         {:ok, profile} <- TrackerGG.splitgate_profile(steam_id),
         {:ok, overview} <- TrackerGG.get_splitgate_lifetime_overview(profile),
         {:ok, embed} <- init_embed(member, overview),
         {:ok, response} <- init_response(embed),
         {:ok} <- create_interaction_response(iaction, response) do
      {:noreply, state}
    else
      {:error, error} ->
        response = %{type: 4, data: %{content: "Unknown error happened: #{inspect(error)}"}}
        create_interaction_response(iaction, response)
        {:noreply, state}
    end
  end

  def init_embed(%User{username: username}, segment) do
    IO.inspect(segment, limit: :infinity)

    embed =
      %Embed{}
      |> Embed.put_image(segment.stats["rankLevel"]["metadata"]["imageUrl"])
      |> Embed.put_title("Splitgate stats for #{username}")
      |> Embed.put_field("Rank", to_string(segment.stats["rankLevel"]["metadata"]["rankName"]))
      |> Embed.put_field("Level", to_string(segment.stats["progressionLevel"]["value"]))
      |> Embed.put_field("Portals created", to_string(segment.stats["portalsSpawned"]["value"]))
      |> Embed.put_field("Portal Entered", to_string(segment.stats["ownPortalsEntered"]["value"]))
      |> Embed.put_field("Teabags", to_string(segment.stats["teabags"]["value"]))
      |> Embed.put_field("Kill/Death Ratio", to_string(segment.stats["kd"]["value"]))

    {:ok, embed}
  end

  def init_response(embed) do
    response = %{
      type: 4,
      data: %{
        embeds: [embed]
      }
    }

    {:ok, response}
  end
end
