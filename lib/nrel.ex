defmodule Nrel do
  @api_key Application.get_env(:miata_bot, __MODULE__)[:api_key]

  use Tesla

  plug Tesla.Middleware.Logger
  plug Tesla.Middleware.BaseUrl, "https://developer.nrel.gov/api"
  plug Tesla.Middleware.Headers, []
  plug Tesla.Middleware.JSON

  def e85_stations_by_state(state, params \\ %{}) do
    Map.merge(params, %{fuel_type: "E85", state: state, status: "E", access: "public"})
    |> alt_fuel_stations()
  end

  def e85_stations_by_zip(zip, params \\ %{}) do
    Map.merge(params, %{fuel_type: "E85", zip: zip, status: "E", access: "public"})
    |> alt_fuel_stations()
  end

  def alt_fuel_stations(params) do
    case get(client(params), "/alt-fuel-stations/v1.json") do
      {:ok, %{body: %{"fuel_stations" => stations}}} -> {:ok, stations}
      _ -> :error
    end
  end

  def client(params) do
    params = Map.to_list(params)

    Tesla.client([
      {Tesla.Middleware.Query, [{:api_key, @api_key} | params]}
    ])
  end
end
