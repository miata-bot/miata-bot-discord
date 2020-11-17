defmodule MiataBotDiscord.OAuth do
  @client_id Application.get_env(:nostrum, :client_id)
  @client_secret Application.get_env(:nostrum, :client_secret)

  use Tesla
  require Logger
  plug Tesla.Middleware.Logger
  plug Tesla.Middleware.BaseUrl, "https://discord.com/api/v8"

  plug Tesla.Middleware.Headers, [
    # {"Authorization", "Bot " <> @token}
  ]

  plug Tesla.Middleware.FormUrlencoded
  plug Tesla.Middleware.FollowRedirects

  if Mix.env() == :prod do
    @url "https://chromo.id/discord/oauth"
  else
    @url "http://localhost:4000/discord/oauth"
  end

  # @url "https://discord.com/api/oauth2/authorize?client_id=755805360123805987&redirect_uri=https%3A%2F%2Fchromo.id%2Fdiscord%2Foauth&response_type=code&scope=identify%20email%20connections%20guilds%20gdm.join%20guilds.join%20activities.read%20activities.write"
  def authorization_url(state \\ "") do
    query =
      URI.encode_query(%{
        "client_id" => @client_id,
        "prompt" => "consent",
        "redirect_uri" => @url,
        "response_type" => "code",
        "scope" => "identify email",
        "state" => state
      })

    %URI{
      authority: "discord.com",
      fragment: nil,
      host: "discord.com",
      path: "/api/oauth2/authorize",
      port: 443,
      query: query,
      scheme: "https",
      userinfo: nil
    }
    |> to_string()

    # "https://discord.com/api/oauth2/authorize?client_id=755805360123805987&redirect_uri=https%3A%2F%2Fchromo.id%2Fdiscord%2Foauth&response_type=code&scope=identify%20email%20connections%20guilds%20gdm.join%20guilds.join%20activities.read%20activities.write"
  end

  def client(%{"access_token" => token, "token_type" => type}) do
    middleware = [
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"Authorization", "#{type} " <> token}]}
    ]

    Tesla.client(middleware)
  end

  def exchange_code(code) do
    response =
      post!("/oauth2/token", %{
        client_id: @client_id,
        client_secret: @client_secret,
        grant_type: "authorization_code",
        code: code,
        redirect_uri: @url,
        scope: "identify email guilds"
      })

    Logger.info("exchange_code: #{code} => #{inspect(response)}")

    with %Tesla.Env{status: 200} = env <- response,
         {:ok, %Tesla.Env{body: body}} <- Tesla.Middleware.JSON.decode(env, []) do
      # refresh_token(body)
      client(body)
    else
      %Tesla.Env{} = env ->
        {:ok, env} = Tesla.Middleware.JSON.decode(env, [])
        raise inspect(env.body)
    end
  end

  def refresh_token(%{"refresh_token" => refresh_token} = body) do
    response =
      post!(client(body), "/oauth2/token", %{
        client_id: @client_id,
        client_secret: @client_secret,
        grant_type: "refresh_token",
        refresh_token: refresh_token,
        redirect_uri: @url,
        scope: "identify email connections"
      })

    Logger.info("refresh token => #{inspect(response)}")

    with %Tesla.Env{status: 200} = env <- response,
         {:ok, %Tesla.Env{body: body}} <- Tesla.Middleware.JSON.decode(env, []) do
      # {client(body), body}
      client(body)
    else
      %Tesla.Env{} = env ->
        {:ok, env} = Tesla.Middleware.JSON.decode(env, [])
        raise inspect(env.body)
    end
  end

  def me(client) do
    case get(client, "/users/@me", query: []) do
      {:ok, %Tesla.Env{body: body}} -> {:ok, body}
      error -> error
    end
  end
end
