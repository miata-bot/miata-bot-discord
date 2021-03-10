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
    send(self(), :get_herc_owns)

    {:producer_consumer,
     %{
       guild: guild,
       current_user: current_user,
       config: config,
       british_spellings: %{},
       hercisms: %{}
     }, subscribe_to: [via(guild, EventDispatcher)]}
  end

  @impl GenStage
  def handle_info(:get_british_spellings, state) do
    case BritishSpellings.british_spellings() do
      {:ok, data} ->
        {:noreply, [], %{state | british_spellings: data}}

      {:error, _} ->
        {:noreply, [], state}
    end
  end

  def handle_info(:get_herc_owns, state) do
    case MiataBotDiscord.api().get_channel_messages(819_293_812_022_575_154, 100) do
      {:ok, messages} ->
        hercisms =
          Map.new(messages, fn %{content: content} -> {String.downcase(content), true} end)

        {:noreply, [], %{state | hercisms: hercisms}}

      _ ->
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

        {:MESSAGE_CREATE, %{channel_id: 819_293_812_022_575_154, content: content}},
        {actions, state} ->
          {actions, %{state | hercisms: Map.put(state.hercisms, String.downcase(content), true)}}

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
    case process_content(message, state.british_spellings, state.hercisms) do
      {:ok, action} -> {actions ++ [action], state}
      _ -> {actions, state}
    end
  end

  def process_content(
        %Nostrum.Struct.Message{content: content} = message,
        british_spellings,
        hercisms
      )
      when is_binary(content) do
    murican_spelling =
      Enum.find(String.split(content, " "), fn word ->
        word = String.trim(String.downcase(word))
        british_spellings[word] || hercisms[word]
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
end
