defmodule MiataBotDiscord.InventoryListener do
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
    {:ok, embed, record} = next_card_embed(state.assigns.cards[user_id])

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

    create_interaction_response(iaction, response)

    {:noreply,
     state
     |> assign(:cards, Map.put(state.assigns.cards, user_id, record))}
  end

  def handle_interaction_create(%Interaction{data: %{custom_id: "inventory.previous." <> user_id}} = iaction, state) do
    {:ok, embed, record} = previous_card_embed(state.assigns.cards[user_id])

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

    create_interaction_response(iaction, response)

    {:noreply,
     state
     |> assign(:cards, Map.put(state.assigns.cards, user_id, record))}
  end

  def handle_interaction_create(unhandled, state) do
    IO.inspect(unhandled, label: "UNHANDLED")
    {:noreply, state}
  end

  def handle_inventory(%{data: %{options: [%{name: "user", type: 6, value: user_id}]}} = iaction, state) do
    with {:ok, %{cards: cards}} <- Partpicker.user(user_id),
         {:ok, embed} <- init_embed(cards, user_id) do
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

      create_interaction_response(iaction, response)

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
    IO.inspect(iaction)
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

    case Enum.at(cards, index + 1) do
      %Partpicker.Card{} = card ->
        embed =
          %Embed{}
          |> Embed.put_title("Listing cards")
          |> Embed.put_description(user <> "'s cards")
          |> Embed.put_image(card.asset_url)
          |> Embed.put_field("Name", card.id)

        {:ok, embed, {cards, user_id, index + 1}}

      nil ->
        {:error, "idk"}
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
          |> Embed.put_field("Name", card.id)

        {:ok, embed, {cards, user_id, index - 1}}

      nil ->
        {:error, "idk"}
    end
  end
end
