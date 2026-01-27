defmodule MiataBotDiscord.AutoreplyListener do
  use Quarrel.Listener
  import MiataBotDiscord.AutoreplyListener.Bang

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl Quarrel.Listener
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

  bang(
    "?crashedmycarintoabridge",
    "I love it"
  )

  bang(
    "?baled",
    "https://tenor.com/view/funny-epic-fail-hay-rolling-gif-17133418"
  )

  def handle_message_create(_message, state) do
    {:noreply, state}
  end
end
