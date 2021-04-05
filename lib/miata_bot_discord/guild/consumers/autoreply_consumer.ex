defmodule MiataBotDiscord.Guild.AutoreplyConsumer do
  @moduledoc """
  Processes commands from users
  """

  use GenStage
  require Logger
  import MiataBotDiscord.Guild.Registry, only: [via: 2]
  alias MiataBotDiscord.Guild.EventDispatcher
  import MiataBotDiscord.Guild.AutoreplyConsumer.Bang

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

  bang("ya rip", "https://www.youtube.com/watch?v=fKLmZNnMT0A")
  bang("yeah rip", "https://www.youtube.com/watch?v=fKLmZNnMT0A")

  bang("!rotaryroast", "https://www.stancenation.com/wp-content/uploads/2012/04/1211.jpg")

  bang(
    "!monstertruck",
    "https://cdn.discordapp.com/attachments/500143495043088395/590656753583259658/20190610_170551_HDR.jpg"
  )

  bang(
    "!longintake",
    "https://cdn.discordapp.com/attachments/384483113985900544/592810948201545739/IMG_20190613_153900.jpg"
  )

  bang(
    "!doot",
    "https://youtu.be/eVrYbKBrI7o"
  )

  bang(
    "!boogerwelds",
    "https://media.discordapp.net/attachments/500143495043088395/631212983875272754/MvLRsuarIkV9veiMwWjIOT3MMVSIiqAp-mYEYVJtSuXroGeOzp5CVWNZ8TZ8pcG13CiXpjIW823BjyZNL-ABnj4mC_sdNKETxtc9.png?width=494&height=659"
  )

  def handle_message(_message, {actions, state}) do
    {actions, state}
  end
end
