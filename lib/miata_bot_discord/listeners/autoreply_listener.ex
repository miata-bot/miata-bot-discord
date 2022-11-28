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
    "!carcover",
    """
    Basically what happens, is that any car cover, no matter how soft the inside layer claims to be, will scratch / abrade the hell out of your paint when the wind blows and the cover moves around. 3 main ways this happens:
    1. Just general dry contact. Even a dry microfiber towel will cause scratches if not lubricated somehow (granted they’re small, but if you do it a bunch they’ll build up over time)
    2. Dirt / Grit. It’ll get under the cover, whether it was there before you put it on or gets blown under by the wind. Then the cover will move around and grind that dirt into the paint, causing holograms. 
    3. Pressure points. If you try to really cinch the cover down so it doesn’t move around (pro tip, this impossible and the wind will find a way), you’ll create pressure points along body lines, edges, etc where the cover will press down harder than it should. This will amplify the effects of the first two issues.
    This isn’t even getting into them trapping moisture which can be a pain too, but basically outdoor car covers are a giant marketing ploy and are all trash. Anyone reasonably knowledgable in detailing will recommend you run like hell from them.
    """
  )

  def handle_message_create(_message, state) do
    {:noreply, state}
  end
end
