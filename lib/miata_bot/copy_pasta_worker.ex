defmodule MiataBot.CopyPastaWorker do
  @messages [
    """
    It's the best! It's Number One. It's Number One. It's always Number One. 
    It's the best! It's the best sports car! 
    It's the gleaming gold standard against all which all small sports cars 
    must be measured. Mazda made so many of them that the prices stay low 
    so anyone can own one. And they're the best! They're the best! They're 
    Number One! You drive a Miata because you want the best and you 
    DESERVE the best! Only the best will do!
    """,
    """
    Many people always ask me how I was able to get into Harvard as a 16 year old 
    who skipped 3 grades of high school. They think I got in because of my scholarly 
    records, but no the key is the interview. As I sat in the Harvard Dean's 
    office in front of the board of reviewers for my application, the Dean 
    asks me "Why should you be a good candidate for this school?" They seemed bored 
    but I replied "Well I was born a child prodigy, placed 1st in my state spelling 
    bee for three consecutive years, I can speak eight different languages not 
    counting Latin. I guess you can say I'm pretty smart. :)
    """,
    """
    I'm Harambe, and this is my zoo enclosure. I work here with my zoo keeper and 
    my friend, cecil the lion. Everything in here has a story and a price. One 
    thing I've learned after 21 years - you never know WHO is gonna come over 
    that fence.
    """,
    """
    Hey, Vsauce, Michael here! Down here. But which way is down? And how much 
    does down weigh? Well, down weighs about 1/100 of a g/cm3 .  It is light, and 
    airy, which makes it a great source of insulation and buoyancy for waterbirds.  
    But if you let go of down, it falls down. So that's which way down is, it's 
    the direction that gravity is pulling everything. Now for someone on the other 
    side of the Earth, my down is their up, but where are falling things going? Why 
    do things fall? Are they being pushed or pulled? Or, is it because of TIME  TRAVEL.
    """,
    """
    You know what? I'll have you know that when I'm at max strength, I can break a 
    bone in your body with ONE PUNCH. Seriously, ask my brother.
    """,
    """
    What you guys have no Szechuan sauce? I WANT SZECHUAN SAUCE! WHERE'S MY SZECHUAN 
    SAUCE??!! I'M PICKLE RICK!!!!!!!! WUBBALUBBADUBDUB!!!!!! I'M PICKLE RICK!!!! 
    REEEEEEEEE!!!! REEEEE!!!! REEEEE!!!! IM PICKLE REEEEEEEEE!!!! REEEEEE!!!!!
    """,
    """
    Why is everyone criticising EA? I've only ever known EA as an excellent video 
    game company and pioneer of the early home computer games industry. EA has always 
    had my enjoyment as their primary concern and their community involvement is 
    phenomenal
    """,
    """
    Don't even try to insult my content, My content is decent, I have some people 
    with over thousands of subs subscribe to me, And many likes and views on my 
    videos,Don't insult my content at all, If you think it's bad, then I dare you 
    to make something better than it and get 100 subs
    """,
    """
    The community here is cancer. Everything is being swallowed by copypastas. 
    The comments section of every post is slowly degrading into a shitfesty 
    circlejerk. Even this is going to end up as a copypasta, I guarantee it.
    """,
    "Non-bee related line near the start, to throw us off the scent.",
    "You may trash your hotel room if there were a bee in it and you were trying to kill it.",
    "Bees are found on some islands.",
    """
    bee bee bees bee-men bees bee bee bees bee bees bees bees bees bee bee bee 
    bee bees beer bee bees bee bee bee bee bee bee bee bee bee bees bee been 
    bee-ish bee bee bee bee bee bee bee bee bee bee bee been bee bee-ish bees 
    bee bees been bee bee bee bee bee bee been been bees bees honeybee bee bee 
    bees bee bee bees beekeepers beekeeper bee-free-ers bees bees bees been 
    been honeybees bees bees bees bees bees bees bee bee bees been bees bees 
    """,
    "I've never seen a diamond in the flesh",
    """
    EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
    """,
    """
    Avenged sevenfold 
    Papa roach 
    A day to remember 
    Five finger death punch
    Falling in reverse 
    """,
    """
    GUYS! STOP CUSSING MY MOM CHECKS MY PHONE EVERYNIGHT AND IF SHE SEES THAT YOU 
    GUYS ARE CUSSING SHE'LL GET REALLY MAD AT ME AND I WILL GET IN TROUBLE! 
    """
  ]

  @timeout 60_000

  @max 5

  require Logger

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def activity(message) do
    GenServer.cast(__MODULE__, {:activity, message})
  end

  def init(_) do
    {:ok, 0, @timeout}
  end

  def handle_info(:timeout, old) do
    old > 0 && Logger.info("resetting counter from: #{old}")
    {:noreply, 0, @timeout}
  end

  def random(), do: Enum.random(@messages)

  def handle_cast({:activity, message}, @max) do
    Logger.info("reached max: #{@max}")
    copy_pasta = Enum.random(@messages)
    Nostrum.Api.create_message(message.channel_id, content: copy_pasta, tts: true)
    {:noreply, 0, @timeout}
  end

  def handle_cast({:activity, _message}, count) do
    Logger.info("incrementing counter: #{count + 1}")
    {:noreply, count + 1, @timeout}
  end
end
