defmodule MiataBotDiscord.TCGListener do
  @moduledoc """
  Randomly distributes virtual cards to a channel
  """

  use Quarrel.Listener
  require Logger

  @impl GenServer
  def init(state) do
    timer = Process.send_after(self(), :generate_card, 3_600_000)

    {:ok,
     state
     |> assign(:timer, timer)}
  end

  @impl GenServer
  def handle_info(:generate_card, state) do
    with {:ok, card} <- MiataBot.Partpicker.generate_random_card(),
         {:ok, embed} <- offer_embed(card),
         {:ok, message} <- create_message(state.config.tcg_channel_id, embed: embed),
         {:ok} <- create_reaction(message.channel_id, message.id, offer_emoji(card)) do
      Logger.info("Card offered")
    end

    timer = Process.send_after(self(), :generate_card, 2_700_000 + Enum.random(0..900_000))

    {:noreply,
     state
     |> assign(:timer, timer)}
  end

  def offer_embed(card) do
    embed =
      %Embed{}
      |> Embed.put_title("New card available")
      |> Embed.put_image(card.asset_url)
      |> Embed.put_url("https://miatapartpicker.gay/cards")
      |> Embed.put_description(
        "React with the right emote to be gifted a card idk. it'll expire soon"
      )

    {:ok, embed}
  end

  def offer_emoji(_card) do
    Enum.random(
      ~w(🏁 🐔 ⛎ 🎳 💃 🔝 👉 🔥 🛌 ❗️ 👘 🚦 😱 🙇 🍰 😻 🍗 🌯 🏷 🍫 🚼 ⏏ 🈴 💥 ⌛️ 🆚 🌃 3️⃣ 👝 🌳 🍔 📎 😦 🌱 💏 📳 🤖 8️⃣ 👳 😿 ⏭ 🍘 🆗 🗓 ◀️ ✌️ ⛓ 🚿 ▪️ 📁 📈 🖖)
    )
  end
end
