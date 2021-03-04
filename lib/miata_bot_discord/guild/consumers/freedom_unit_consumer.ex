defmodule MiataBotDiscord.Guild.FreedomUnitConsumer do
  @moduledoc """
  Processes commands from users
  """

  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.EventDispatcher
  alias Nostrum.Struct.Message

  # ₳฿₿￠₡¢₢₵₫€￡£₤₣ƒ₲₭Ł₥₦₽₱＄$₮ℳ₶₩￦¥￥₴₸¤₰៛₪₯₠₧﷼円元圓㍐원৳₹₨৲௹

  @doc false
  def start_link({guild, config, current_user}) do
    GenStage.start_link(__MODULE__, {guild, config, current_user}, name: via(guild, __MODULE__))
  end

  @impl GenStage
  def init({guild, config, current_user}) do
    {:producer_consumer, %{guild: guild, current_user: current_user, config: config},
     subscribe_to: [via(guild, EventDispatcher)]}
  end

  @impl GenStage
  def handle_events(events, _from, %{current_user: %{id: current_user_id}} = state) do
    {actions, state} =
      Enum.reduce(events, {[], state}, fn
        # Ignore messages from self
        {:MESSAGE_CREATE, %{author: %{id: author_id}}}, {actions, state}
        when author_id == current_user_id ->
          {actions, state}

        {:MESSAGE_CREATE, message}, {actions, state} ->
          handle_message(message, {actions, state})

        _, {actions, state} ->
          {actions, state}
      end)

    {:noreply, actions, state}
  end

  def handle_message(
        %Message{referenced_message: %Message{content: content}, content: "!freedomunit" <> _} =
          message,
        {actions, state}
      ) do
    action = generate_action(message, content)

    {actions ++ [action], state}
  end

  def handle_message(
        %Message{content: "!freedomunit " <> content} = message,
        {actions, state}
      ) do
    action = generate_action(message, content)

    {actions ++ [action], state}
  end

  def handle_message(_message, {actions, state}), do: {actions, state}

  def generate_action(message, content) do
    currency_regex =
      ~r/((?<currency>[₳฿₿￠₡¢₢₵₫€￡£₤₣ƒ₲₭Ł₥₦₽₱＄\$₮ℳ₶₩￦¥￥₴₸¤₰៛₪₯₠₧﷼円元圓㍐원৳₹₨৲௹kr])(?<data>\d+))/

    length_regex = ~r/((?<data>\d+)(?<unit>mm|m|cm))/

    cond do
      Regex.match?(currency_regex, content) ->
        handle_currency(currency_regex, message, content)

      Regex.match?(length_regex, content) ->
        handle_length(length_regex, message, content)
    end
  end

  def handle_currency(currency_regex, message, content) do
    case Regex.named_captures(currency_regex, content) do
      %{"data" => data, "currency" => currency} ->
        Logger.info("uri=#{inspect(data)}")

        q =
          URI.encode_query(%{q: "convert #{currency}#{data} to USD", hl: "EN", ip: "10.10.10.10"})

        url = "https://google.com/?#{q}"
        {:ok, png} = Webdriver.screenshot(url)

        args = [
          content: "just use google you lazy shit",
          file: %{name: "conversion.png", body: png}
        ]

        {:create_message!, [message.channel_id, args]}

      _ ->
        {:create_message!,
         [message.channel_id, "#{message.author} idk how to help you w/ that sry"]}
    end
  end

  def handle_length(currency_regex, message, content) do
    case Regex.named_captures(currency_regex, content) do
      %{"data" => data, "unit" => unit} ->
        Logger.info("uri=#{inspect(data)}")

        q =
          URI.encode_query(%{q: "convert #{data}#{unit} to imperial", hl: "EN", ip: "10.10.10.10"})

        url = "https://google.com/?#{q}"
        {:ok, png} = Webdriver.screenshot(url)

        args = [
          content: "just use google you lazy shit",
          file: %{name: "conversion.png", body: png}
        ]

        {:create_message!, [message.channel_id, args]}

      _ ->
        {:create_message!,
         [message.channel_id, "#{message.author} idk how to help you w/ that sry"]}
    end
  end
end
