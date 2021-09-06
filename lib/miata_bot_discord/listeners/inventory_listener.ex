defmodule MiataBotDiscord.InventoryListener do
  require Logger
  use Quarrel.Listener
  alias MiataBot.Partpicker

  @impl GenServer
  def init(state) do
    {:ok,
     state
     |> assign(:cards, %{})}
  end

  @impl Quarrel.Listener
  def handle_interaction_create(%Interaction{data: %{name: "inventory"}} = iaction, state) do
    handle_inventory(iaction, state)
  end

  def handle_interaction_create(%Interaction{data: %{custom_id: "inventory.next." <> user_id}} = iaction, state) do
    with {:ok, embed, record} <- next_card_embed(state.assigns.cards[user_id]),
         {:ok, response} <- update_inventory_response(embed, user_id),
         {:ok} <- create_interaction_response(iaction, response) do
      {:noreply,
       state
       |> assign(:cards, Map.put(state.assigns.cards, user_id, record))}
    else
      {:error, error} ->
        response = %{type: 4, data: %{content: "Unknown error happened: #{inspect(error)}"}}
        create_interaction_response(iaction, response)
        {:noreply, state}
    end
  end

  def handle_interaction_create(%Interaction{data: %{custom_id: "inventory.previous." <> user_id}} = iaction, state) do
    with {:ok, embed, record} <- previous_card_embed(state.assigns.cards[user_id]),
         {:ok, response} <- update_inventory_response(embed, user_id),
         {:ok} <- create_interaction_response(iaction, response) do
      {:noreply,
       state
       |> assign(:cards, Map.put(state.assigns.cards, user_id, record))}
    else
      {:error, error} ->
        response = %{type: 4, data: %{content: "Unknown error happened: #{inspect(error)}"}}
        create_interaction_response(iaction, response)
        {:noreply, state}
    end
  end

  def handle_interaction_create(_, state) do
    {:noreply, state}
  end

  def handle_inventory(%{data: %{options: [%{name: "user", type: 6, value: user_id}]}} = iaction, state) do
    with {:ok, %{cards: cards}} <- Partpicker.user(user_id),
         {:ok, embed} <- init_embed(cards, user_id),
         {:ok, response} <- init_inventory_response(embed, user_id),
         {:ok} <- create_interaction_response(iaction, response) do
      {:noreply,
       state
       |> assign(:cards, Map.put(state.assigns.cards, to_string(user_id), {cards, user_id, 0}))}
    else
      error ->
        response = %{type: 4, data: %{content: "Unknown error happened: #{inspect(error)}"}}
        create_interaction_response(iaction, response)
        {:noreply, state}
    end
  end

  def handle_inventory(%{member: %{user: %{id: user_id}}} = iaction, state) do
    with {:ok, %{cards: cards}} <- Partpicker.user(user_id),
         {:ok, embed} <- init_embed(cards, user_id),
         {:ok, response} <- init_inventory_response(embed, user_id),
         {:ok} <- create_interaction_response(iaction, response) do
      {:noreply,
       state
       |> assign(:cards, Map.put(state.assigns.cards, to_string(user_id), {cards, user_id, 0}))}
    else
      error ->
        response = %{type: 4, data: %{content: "Unknown error happened: #{inspect(error)}"}}
        create_interaction_response(iaction, response)
        {:noreply, state}
    end
  end

  def handle_inventory(iaction, state) do
    response = %{type: 4, data: %{content: "Failed to process interaction sorry"}}
    create_interaction_response(iaction, response)
    {:noreply, state}
  end

  def init_embed([%Partpicker.Card{} = card | _], user_id) do
    user = %User{id: user_id} |> User.mention()

    embed =
      %Embed{}
      |> Embed.put_title("Listing cards")
      |> Embed.put_description(user <> "'s cards")
      |> Embed.put_image(card.asset_url)
      |> Embed.put_field("Name", card.id)

    {:ok, embed}
  end

  def next_card_embed({cards, user_id, index}) do
    user = %User{id: user_id} |> User.mention()

    if index >= Enum.count(cards) - 1 do
      next_card_embed({cards, user_id, -1})
    else
      case Enum.at(cards, index + 1) do
        %Partpicker.Card{} = card ->
          embed =
            %Embed{}
            |> Embed.put_title("Listing cards")
            |> Embed.put_description(user <> "'s cards")
            |> Embed.put_image(card.asset_url)
            |> Embed.put_field("ID", card.id)

          {:ok, embed, {cards, user_id, index + 1}}

        nil ->
          {:error, "idk"}
      end
    end
  end

  def previous_card_embed({cards, user_id, index}) do
    user = %User{id: user_id} |> User.mention()

    case Enum.at(cards, index - 1) do
      %Partpicker.Card{} = card ->
        embed =
          %Embed{}
          |> Embed.put_title("Listing cards")
          |> Embed.put_description(user <> "'s cards")
          |> Embed.put_image(card.asset_url)
          |> Embed.put_field("ID", card.id)

        {:ok, embed, {cards, user_id, index - 1}}

      nil ->
        {:error, "idk"}
    end
  end

  def update_inventory_response(embed, user_id) do
    response = %{
      type: 7,
      data: %{
        embeds: [embed],
        components: [
          %{
            type: 1,
            components: [
              %{type: 2, label: "Previous", style: 1, custom_id: "inventory.previous.#{user_id}"},
              %{type: 2, label: "Next", style: 1, custom_id: "inventory.next.#{user_id}"}
            ]
          }
        ]
      }
    }

    {:ok, response}
  end

  def init_inventory_response(embed, user_id) do
    response = %{
      type: 4,
      data: %{
        embeds: [embed],
        components: [
          %{
            type: 1,
            components: [
              %{type: 2, label: "Previous", style: 1, custom_id: "inventory.previous.#{user_id}"},
              %{type: 2, label: "Next", style: 1, custom_id: "inventory.next.#{user_id}"}
            ]
          }
        ]
      }
    }

    {:ok, response}
  end
end
