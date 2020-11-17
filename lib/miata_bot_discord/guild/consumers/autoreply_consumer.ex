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
    "!hercroast",
    "https://cdn.discordapp.com/attachments/500143495043088395/590654628115382277/032216_Fire_Car_AB.jpg"
  )

  bang(
    "!longintake",
    "https://cdn.discordapp.com/attachments/384483113985900544/592810948201545739/IMG_20190613_153900.jpg"
  )

  bang(
    "!18swapintake",
    "https://media.discordapp.net/attachments/322080529245798401/593511885664550921/IMG_1140.jpg"
  )

  bang(
    "!torquespecs",
    "https://www.miata.net/garage/torque.html"
  )

  bang(
    "!fartbeard",
    "https://cdn.discordapp.com/attachments/322162421156282369/593854324891713546/image0.jpg"
  )

  bang(
    "!bmwroast",
    "https://media.discordapp.net/attachments/322162421156282369/593869644365037628/b49d82b0ad.png?width=590&height=658"
  )

  bang("!e", "https://i.ytimg.com/vi/J6NioWmscDc/maxresdefault.jpg")

  bang(
    "!flroast",
    "https://cdn.discordapp.com/attachments/322162421156282369/593905029094572032/florida.gif"
  )

  bang(
    "!floridiaroast",
    "https://cdn.discordapp.com/attachments/322162421156282369/593905029094572032/florida.gif"
  )

  bang(
    "!boing",
    "https://www.youtube.com/watch?v=hoS1MCF8AeI"
  )

  bang(
    "!weed",
    "https://www.youtube.com/watch?v=5lEelz0iUJo"
  )

  bang(
    "!doot",
    "https://youtu.be/eVrYbKBrI7o"
  )

  bang(
    "!nou",
    "https://cdn.discordapp.com/attachments/351767273712910336/594569216640942083/GJElD4jJUQ2xAPwjRIjBcUeAf311aN1oa791xzRpQbVJx1oF-zjoQZ1Sq1R_JpV31jSBPOJ9WvIQvhFDVpp7Cwoaye4yR0VxEOsy.png"
  )

  bang(
    "!rotary",
    "https://www.youtube.com/watch?v=FZUcpVmEHuk"
  )

  bang(
    "!fca",
    "https://www.youtube.com/watch?v=FZUcpVmEHuk"
  )

  bang(
    "!FCA",
    "https://www.youtube.com/watch?v=FZUcpVmEHuk"
  )

  bang(
    "!potato",
    "https://cdn.discordapp.com/attachments/591751583767724042/594582309639028745/unknown.png"
  )

  bang(
    "!playstation",
    "https://youtu.be/oAhvQoLpvsM"
  )

  bang(
    "!theresyourproblem",
    "https://i.kym-cdn.com/photos/images/newsfeed/000/228/269/demotivational-posters-theres-your-problem.jpg"
  )

  bang(
    "!spaghetti",
    "https://media.discordapp.net/attachments/322080529245798401/611652555037999124/RZ1AVzfrlMtElpqJQLAYfshvvmll12ED3q9MILYBYDESQeWyXiCLu0-93k76UCBtN9RFGjMaFoNme8whKXqXQXTZMWSeR4F4K8hS.png?width=494&height=659"
  )

  bang(
    "!boogerwelds",
    "https://media.discordapp.net/attachments/500143495043088395/631212983875272754/MvLRsuarIkV9veiMwWjIOT3MMVSIiqAp-mYEYVJtSuXroGeOzp5CVWNZ8TZ8pcG13CiXpjIW823BjyZNL-ABnj4mC_sdNKETxtc9.png?width=494&height=659"
  )

  def handle_message(_message, {actions, state}) do
    {actions, state}
  end
end
