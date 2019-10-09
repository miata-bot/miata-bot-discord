defmodule MiataBot.Discord.OAuth2 do
  @api_base "https://discordapp.com/api/"
  @oauth_base "https://discordapp.com/api/oauth2/"

  @client_id Application.get_env(:miata_bot, __MODULE__)[:client_id]
  @client_secret Application.get_env(:miata_bot, __MODULE__)[:client_secret]
  @redirect_uri Application.get_env(:miata_bot, __MODULE__)[:redirect_uri]

  def client_id(), do: @client_id
  def client_secret(), do: @client_secret
  def redirect_uri(), do: @redirect_uri

  def get_token(code, scope) do
    body = %{
      code: code,
      grant_type: "authorization_code",
      redirect_uri: @redirect_uri,
      scope: scope
    }

    args = URI.encode_query(body)
    auth = Base.encode64("#{@client_id}:#{@client_secret}")

    authheaders = %{
      "Authorization" => "Basic #{auth}",
      "Content-Type" => "application/x-www-form-urlencoded"
    }

    full_url = "#{@oauth_base}token"

    case HTTPoison.post(full_url, args, authheaders) do
      {:ok, response} -> Jason.decode(response.body)
      error -> error
    end
  end

  def get_token!(code, scope) do
    body = %{
      code: code,
      grant_type: "authorization_code",
      redirect_uri: @redirect_uri,
      scope: scope
    }

    args = URI.encode_query(body)
    auth = Base.encode64("#{@client_id}:#{@client_secret}")

    authheaders = %{
      "Authorization" => "Basic #{auth}",
      "Content-Type" => "application/x-www-form-urlencoded"
    }

    ("#{@oauth_base}token"
     |> HTTPoison.post!(args, authheaders)).body
    |> Jason.decode!()
  end

  def get_userdata!(token) do
    headers = %{
      Authorization: "Bearer #{token}"
    }

    ("#{@api_base}users/@me"
     |> HTTPoison.get!(headers)).body
    |> Jason.decode!()
  end

  def get_guilds!(token) do
    headers = %{
      Authorization: "Bearer #{token}"
    }

    ("#{@api_base}users/@me/guilds"
     |> HTTPoison.get!(headers)).body
    |> Jason.decode!()
    |> Nostrum.Util.enum_to_struct(Nostrum.Struct.Guild)
  end
end
