defmodule MiataBotDiscord.Guild.HercConsumer do
  @moduledoc """
  Processes commands from users
  """

  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.EventDispatcher

  defmodule BritishSpellings do
    use Tesla
    plug Tesla.Middleware.JSON, decode_content_types: ["text/plain"]

    plug Tesla.Middleware.BaseUrl,
         "https://raw.githubusercontent.com/hyperreality/American-British-English-Translator/master/data/"

    def british_spellings do
      case get!("/british_spellings.json") do
        %{status: 200, body: body} -> {:ok, body}
        _ -> {:error, "failed to get spellings"}
      end
    end
  end

  @doc false
  def start_link({guild, config, current_user}) do
    GenStage.start_link(__MODULE__, {guild, config, current_user}, name: via(guild, __MODULE__))
  end

  @impl GenStage
  def init({guild, config, current_user}) do
    send(self(), :get_british_spellings)

    {:producer_consumer,
     %{guild: guild, current_user: current_user, config: config, british_spellings: %{}},
     subscribe_to: [via(guild, EventDispatcher)]}
  end

  def handle_info(:get_british_spellings, state) do
    case BritishSpellings.british_spellings() do
      {:ok, data} ->
        {:noreply, [], %{state | british_spellings: data}}

      {:error, _} ->
        {:noreply, [], state}
    end
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

  def handle_message(message, {actions, state}) do
    if(message.author.id == 226_052_366_745_600_000) do
      # if(message.author.id == 316_741_621_498_511_363) do
      handle_herc(message, actions, state)
    else
      {actions, state}
    end
  end

  def handle_herc(message, actions, state) do
    case process_content(message, state.british_spellings) do
      {:ok, action} -> {actions ++ [action], state}
      _ -> {actions, state}
    end
  end

  def process_content(%Nostrum.Struct.Message{content: content} = message, british_spellings)
      when is_binary(content) do
    murican_spelling =
      Enum.find(String.split(content, " "), fn word ->
        word = String.trim(String.downcase(word))
        british_spellings[word] || hercism?(word)
      end)

    if murican_spelling do
      own_herc_action(message, murican_spelling)
    end
  end

  def process_content(%Nostrum.Struct.Message{}, _), do: nil

  def own_herc_action(
        %Nostrum.Struct.Message{channel_id: channel_id, author: _author, id: message_id},
        _murican_spelling
      ) do
    emoji = %Nostrum.Struct.Emoji{
      animated: false,
      id: 819_288_827_419_033_601,
      managed: false,
      name: "okbritish",
      require_colons: true,
      roles: [],
      user: nil
    }

    {:ok, {:create_reaction, [channel_id, message_id, emoji]}}
  end

  def hercism?("slushmatic"), do: true
  def hercism?("poorsche"), do: true
  def hercism?("saloon"), do: true
  def hercism?(" boot "), do: true
  def hercism?("bonnet"), do: true
  def hercism?("colour"), do: true
  def hercism?("ferd"), do: true
  def hercism?("tyre"), do: true
  def hercism?("mommytank"), do: true
  def hercism?("windscreen"), do: true
  def hercism?("flavour"), do: true
  def hercism?("bloody"), do: true
  def hercism?("twat"), do: true
  def hercism?("winge"), do: true
  def hercism?("carpark"), do: true
  def hercism?("theatre"), do: true
  def hercism?("petrol"), do: true
  def hercism?("motoring"), do: true
  def hercism?("bloke"), do: true
  def hercism?("lad"), do: true
  def hercism?("bollock"), do: true
  def hercism?("wanker"), do: true
  def hercism?("humour"), do: true
  def hercism?("labour"), do: true
  def hercism?("neighbour"), do: true
  def hercism?("4pot"), do: true
  def hercism?(_), do: false
end
