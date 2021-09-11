defmodule MiataBotDiscord.TCGListener do
  @moduledoc """
  Randomly distributes virtual cards to a channel
  """

  use Quarrel.Listener
  require Logger

  def force_generate_card(guild) do
    guild
    |> Quarrel.GuildSupervisor.NameProvider.via(__MODULE__)
    |> GenServer.whereis()
    |> send(:generate_card)
  end

  @impl GenServer
  def init(state) do
    case state.config[:tcg_channel_id] do
      nil ->
        :ignore

      _channel ->
        timer = Process.send_after(self(), :generate_card, 3_600_000)
        _ = Phoenix.PubSub.subscribe(MiataBot.PubSub, "tcg")

        {:ok,
         state
         |> assign(:timer, timer)
         |> assign(:messages, %{})}
    end
  end

  @impl GenServer
  def handle_info(:generate_card, state) do
    tcg_channel_id = state.config.tcg_channel_id
    timer = Process.send_after(self(), :generate_card, random_timeout_ms())

    with {:ok, [%{author: %{id: id}} | _]} when id != state.bot.id <- get_channel_messages(tcg_channel_id, 1),
         {:ok, card} <- MiataBot.Partpicker.generate_random_card(),
         {:ok, embed} <- offer_embed(card),
         {:ok, message} <- create_message(tcg_channel_id, embed: embed),
         {:ok, offer_emoji_a, offer_emoji_b, offer_emoji_c} <- offer_emoji(card),
         {:ok} <- create_reaction_ex(message.channel_id, message.id, offer_emoji_a),
         {:ok} <- create_reaction_ex(message.channel_id, message.id, offer_emoji_b),
         {:ok} <- create_reaction_ex(message.channel_id, message.id, offer_emoji_c) do
      Logger.info("Card offered")
      claim_emoji = Enum.random([offer_emoji_a, offer_emoji_b, offer_emoji_c])

      {:noreply,
       state
       |> assign(:timer, timer)
       |> assign(:messages, Map.put(state.assigns.messages, message.id, {claim_emoji, card}))}
    else
      error ->
        Logger.error("Failed to offer card: #{inspect(error)}")

        {:noreply,
         state
         |> assign(:timer, timer)}
    end
  end

  def handle_info(["RANDOM_CARD_EXPIRE", %{id: id} = card], state) do
    Logger.debug("Card expired")

    expired_message_id =
      Enum.find_value(state.assigns.messages, fn
        {message_id, {_emoji, %{id: ^id}}} ->
          message_id

        {_message_id, _} = a ->
          Logger.info(inspect(a))
          false
      end)

    if expired_message_id do
      Logger.info("Expired card edit")
      {:ok, embed} = expire_embed(card)

      with {:ok, message} <- edit_message(state.config.tcg_channel_id, expired_message_id, embed: embed) do
        delete_all_reactions(state.config.tcg_channel_id, message.id)
      end

      {:noreply, state |> assign(:messages, Map.delete(state.assigns.messages, expired_message_id))}
    else
      Logger.warn("Expired card not found in state")
      {:noreply, state}
    end
  end

  def handle_info(["CREATE_TRADE_REQUEST", request], state) do
    with {:ok, request_embed} <- request_sender_embed(request),
         {:ok, channel} <- create_dm(request.receiver),
         {:ok, components} <- request_sender_components(request),
         {:ok, _} <-
           create_message(channel.id,
             embed: request_embed,
             components: [
               %{
                 type: 1,
                 components: components
               }
             ]
           ) do
      {:noreply, state}
    else
      error ->
        Logger.error "Failed to handle trade request create: #{inspect(error)}"
        {:noreply, state}
    end
  end

  @impl Quarrel.Listener
  def handle_interaction_create(arg0, state) do
    IO.inspect(arg0)
    {:noreply, state}
  end

  @impl Quarrel.Listener
  def handle_message_reaction_add(%{user_id: user_id}, %{bot: %{id: user_id}} = state) do
    {:noreply, state}
  end

  def handle_message_reaction_add(%{user_id: user_id, message_id: message_id, emoji: %{name: claim_emoji}}, state) do
    case state.assigns.messages[message_id] do
      {^claim_emoji, card} ->
        handle_claim_card(card, user_id, message_id, state)

      _ ->
        # reacted to the wrong one or not a offer message
        {:noreply, state}
    end
  end

  def handle_claim_card(card, user_id, message_id, state) do
    with {:ok, card} <- MiataBot.Partpicker.claim_card(card, user_id),
         {:ok} <- delete_message(state.config.tcg_channel_id, message_id),
         {:ok, claim_embed} <- claim_embed(card, user_id),
         {:ok, _} <- create_message(state.config.tcg_channel_id, embed: claim_embed) do
      {:noreply, state |> assign(:messages, Map.delete(state.assigns.messages, message_id))}
    end
  end

  def offer_embed(card) do
    embed =
      %Embed{}
      |> Embed.put_title("New card available")
      |> Embed.put_image(card.asset_url)
      |> Embed.put_url("https://miatapartpicker.gay/cards")
      |> Embed.put_description("React with the right emote to be gifted a card idk. it'll expire soon")

    {:ok, embed}
  end

  def claim_embed(card, user_id) do
    embed =
      %Embed{}
      |> Embed.put_title("Card has been claimed")
      |> Embed.put_image(card.asset_url)
      |> Embed.put_url("https://miatapartpicker.gay/cards")
      |> Embed.put_description(User.mention(%User{id: user_id}) <> " Has claimed this card.")

    {:ok, embed}
  end

  def expire_embed(card) do
    embed =
      %Embed{}
      |> Embed.put_title("Card expired")
      |> Embed.put_image(card.asset_url)
      |> Embed.put_url("https://miatapartpicker.gay/cards")
      |> Embed.put_description("get rekt idiot")

    {:ok, embed}
  end

  def request_sender_embed(request) do
    sender = User.mention(%User{id: request.sender})

    embed =
      %Embed{}
      |> Embed.put_title("New Trade Request")
      |> Embed.put_description(sender <> " offers to you")
      |> Embed.put_image(request.offer.asset_url)
      |> Embed.put_url("https://miatapartpicker.gay/cards")

    {:ok, embed}
  end

  def request_receiver_embed(request) do
    receiver = User.mention(%User{id: request.receiver})

    embed =
      %Embed{}
      |> Embed.put_title("New Trade Request")
      |> Embed.put_description(receiver <> " will receive")
      |> Embed.put_image(request.trade.asset_url)
      |> Embed.put_url("https://miatapartpicker.gay/cards")

    {:ok, embed}
  end

  def request_sender_components(request) do
    components = [
      %{type: 2, label: "Accept", style: 3, custom_id: "trade_request.accept.#{request.id}"},
      %{type: 2, label: "Decline", style: 4, custom_id: "trade_request.decline.#{request.id}"},
      %{type: 2, label: "Next", style: 1, custom_id: "trade_request.next.#{request.id}"}
    ]
    {:ok, components}
  end

  def request_receiver_components(request) do
    components = [
      %{type: 2, label: "Accept", style: 3, custom_id: "trade_request.accept.#{request.id}"},
      %{type: 2, label: "Decline", style: 4, custom_id: "trade_request.decline.#{request.id}"},
      %{type: 2, label: "Previous", style: 1, custom_id: "trade_request.previous.#{request.id}"}
    ]
    {:ok, components}

  end

  def offer_emoji(_card) do
    [a, b, c] =
      ~w(🏁 🐔 ⛎ 🎳 💃 🔝 👉 🔥 🛌 ❗️ 👘 🚦 😱 🙇 🍰 😻 🍗 🌯 🏷 🍫 🚼 ⏏ 🈴 💥 ⌛️ 🆚 🌃 3️⃣ 👝 🌳 🍔 📎 😦 🌱 💏 📳 🤖 8️⃣ 👳 😿 ⏭ 🍘 🆗 🗓 ◀️ ✌️ ⛓ 🚿 ▪️ 📁 📈 🖖)
      |> Enum.shuffle()
      |> Enum.take(3)

    {:ok, a, b, c}
  end

  def random_timeout_ms(at_least \\ 2_700_000, random_max \\ 900_000) do
    at_least + Enum.random(0..random_max)
  end

  # TODO: Move this into Quarrel - coner

  alias Nostrum.Error.ApiError
  @max_retry_after_ms 2500
  def create_reaction_ex(channel_id, message_id, emoji) do
    case create_reaction(channel_id, message_id, emoji) do
      {:ok} ->
        {:ok}

      {:error, %ApiError{response: %{global: false, retry_after: retry_ms}, status_code: 429}}
      when retry_ms <= @max_retry_after_ms ->
        Process.sleep(retry_ms)
        create_reaction_ex(channel_id, message_id, emoji)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
