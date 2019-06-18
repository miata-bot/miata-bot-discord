defmodule MiataBot.Discord do
  alias MiataBot.{Repo, Carinfo}

  use Nostrum.Consumer
  alias Nostrum.Api
  alias Nostrum.Struct.Embed

  @verification_channel_id 322_127_502_212_333_570

  def start_link do
    Consumer.start_link(__MODULE__, name: __MODULE__)
  end

  # uncomment to own Mark Sticken
  # def handle_event({:MESSAGE_CREATE, {%{author: %{id: 362309360124428299}, channel_id: channel_id} = message}, _state}) do
  #   Api.create_message(channel_id, "<@!362309360124428299> https://media.discordapp.net/attachments/322162421156282369/581557012593246209/13t5kz.jpg")
  #   Api.delete_message(message)
  # end

  # def handle_event({:MESSAGE_CREATE, {%{author: author = %{id: id}, channel_id: channel_id} = message}, _state}) do
  #   IO.inspect(author, label: "AUTHOR")
  # end
  
  def handle_event({:MESSAGE_CREATE, {%{content: "!rotaryroas" <> _, channel_id: channel_id}}, _state}) do
    Api.create_message(channel_id, "https://www.stancenation.com/wp-content/uploads/2012/04/1211.jpg")
  end
  
  def handle_event({:MESSAGE_CREATE, {%{content: "!monstertruc" <> _, channel_id: channel_id}}, _state}) do
    Api.create_message(channel_id, "https://cdn.discordapp.com/attachments/500143495043088395/590656753583259658/20190610_170551_HDR.jpg")
  end

  def handle_event({:MESSAGE_CREATE, {%{content: "!hercroas" <> _, channel_id: channel_id}}, _state}) do
    msg = Enum.random([
      "https://cdn-02.belfasttelegraph.co.uk/sunday-life/news/article37942274.ece/92675/AUTOCROP/w620h342/2019-03-24_sun_48967410_I1.JPG",
      "https://cdn.carbuzz.com/gallery-images/840x560/523000/800/523834.jpg",
      "https://cdn.discordapp.com/attachments/500143495043088395/590654429691248680/mlwmvhh1tzfiuydvxjuu.png",
      "https://cdn.discordapp.com/attachments/500143495043088395/590654628115382277/032216_Fire_Car_AB.jpg"
    ])
    Api.create_message(channel_id, msg <> "\nhttps://static.nhtsa.gov/odi/rcl/2017/RCRIT-17V676-7418.pdf")
  end

  def handle_event({:MESSAGE_CREATE, {%{content: "$" <> command} = message}, _state}) do
    handle_command(command, message)
  end

  def handle_event({:MESSAGE_CREATE, {%{channel_id: @verification_channel_id} = message}, _state}) do
    case message.attachments do
      [%{url: url} | _rest] ->
        year = extract_year(message.content)
        params = %{image_url: url, discord_user_id: message.author.id, year: year}
        do_update(@verification_channel_id, message.author, params)

      _ ->
        :noop
    end
  end

  def handle_event(_), do: :noop

  def handle_command("help", %{channel_id: channel_id}) do
    embed =
      %Embed{}
      |> Embed.put_title("Available commands")
      |> Embed.put_field("carinfo", """
      Shows the author's carinfo
      """)
      |> Embed.put_field("carinfo get <user>", """
      Shows a users carinfo
      """)
      |> Embed.put_field("carinfo update title", """
      Sets the author's carinfo title
      """)
      |> Embed.put_field("carinfo update image", """
      Updates the author's carinfo from an attached photo
      """)
      |> Embed.put_field("carinfo update year <year>", """
      Sets the author's carinfo year
      """)
      |> Embed.put_field("carinfo update color code <color>", """
      Sets the author's carinfo color code
      """)

    Api.create_message(channel_id, embed: embed)
  end

  def handle_command("carinfo", %{channel_id: channel_id, author: author}) do
    embed = carinfo(author)
    Api.create_message(channel_id, embed: embed)
  end

  def handle_command("carinfo get" <> user, %{channel_id: channel_id}) do
    case get_user(user) do
      {:ok, user} ->
        embed = carinfo(user)
        Api.create_message(channel_id, embed: embed)

      {:error, _} ->
        Api.create_message(channel_id, "Could not find user: #{user}")
    end
  end

  def handle_command("carinfo update image" <> _, %{
        channel_id: channel_id,
        author: author,
        attachments: [attachment | _]
      }) do
    params = %{image_url: attachment.url, discord_user_id: author.id}
    do_update(channel_id, author, params)
  end

  def handle_command("carinfo update year " <> year, %{
        channel_id: channel_id,
        author: author
      }) do
    params = %{year: year, discord_user_id: author.id}
    do_update(channel_id, author, params)
  end

  def handle_command("carinfo update color code " <> color_code, %{
        channel_id: channel_id,
        author: author
      }) do
    params = %{color_code: color_code, discord_user_id: author.id}
    do_update(channel_id, author, params)
  end

  def handle_command("carinfo update title " <> title, %{
        channel_id: channel_id,
        author: author
      }) do
    params = %{title: title, discord_user_id: author.id}
    do_update(channel_id, author, params)
  end

  def handle_command(_command, message) do
    IO.inspect(message, label: "unhandled command")
  end

  def do_update(channel_id, author, params) do
    info = Repo.get_by(Carinfo, discord_user_id: author.id) || %Carinfo{}
    changeset = Carinfo.changeset(info, params)

    embed =
      case Repo.insert_or_update(changeset) do
        {:ok, _} ->
          carinfo(author)

        {:error, changeset} ->
          changeset_to_error_embed(changeset)
      end

    Api.create_message(channel_id, embed: embed)
  end

  def changeset_to_error_embed(changeset) do
    embed = Embed.put_title(%Embed{}, "Error performing action #{changeset.action}")

    Enum.reduce(changeset.errors, embed, fn {key, {msg, _opts}}, embed ->
      Embed.put_field(embed, to_string(key), msg)
    end)
  end

  def carinfo(author) do
    case Repo.get_by(Carinfo, discord_user_id: author.id) do
      nil ->
        %Embed{}
        |> Embed.put_title("#{author.username}'s Miata")
        |> Embed.put_description("#{author.username} has not registered a vehicle.")

      %Carinfo{} = info ->
        %Embed{}
        |> Embed.put_title(info.title || "#{author.username}'s Miata")
        |> Embed.put_color(info.color || 0xD11A06)
        |> Embed.put_field("Year", info.year || "unknown year")
        |> Embed.put_field("Color Code", info.color_code || "unknown color code")
        |> Embed.put_image(info.image_url)
    end
  end

  defp extract_year(_), do: nil

  defp get_user("<@!" <> almost_snowflake) do
    snowflake = String.trim_trailing(almost_snowflake, ">")
    get_user(snowflake)
  end

  defp get_user(user) do
    case Nostrum.Snowflake.cast(user) do
      {:ok, snowflake} ->
        Api.get_user(snowflake)

      _ ->
        {:error, "unknown user"}
    end
  end
end
