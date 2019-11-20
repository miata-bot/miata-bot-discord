defmodule PastebinRandomizer do
  require Logger
  use GenServer

  def good_paste do
    Enum.random([
      "QzJzqDri",
      "ct6iVh8u",
      "nMJhgT79",
      "1yM2E62D",
      "DLSJxeya",
      "QcGKqgBL",
      "UZyzFued",
      "3uHn4nwL",
      "Xgrt1vGm",
      "6BkL68SP",
      "0MH2Up4c"
    ])
  end

  def get(key) do
    {:ok, body} = GenServer.call(__MODULE__, {:get, key})
    Enum.random(body)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    __MODULE__ = :ets.new(__MODULE__, [:named_table, :bag])
    {:ok, %{table: __MODULE__}}
  end

  def handle_call({:get, key}, _from, state) do
    reply = do_get(state.table, key)
    {:reply, reply, state}
  end

  def do_get(table, key) do
    case :ets.lookup(table, key) do
      [] ->
        case http_get(key) do
          {:ok, pastas} ->
            data = Enum.map(pastas, fn pasta -> {key, pasta} end)
            true = :ets.insert(table, data)
            {:ok, pastas}

          :error ->
            :error
        end

      copy_pastas ->
        {:ok, Enum.map(copy_pastas, fn {^key, pasta} -> pasta end)}
    end
  end

  defp http_get(key) do
    Logger.info("Doing http request for https://pastebin.com/raw/#{key}")

    case :httpc.request(:get, {'https://pastebin.com/raw/#{key}', []}, [], body_format: :binary) do
      {:ok, {_, _, body}} ->
        body =
          body
          |> String.split("\r\n\r\n")
          |> Enum.map(&String.trim(&1))
          |> Enum.filter(fn str -> String.length(str) > 1 end)

        {:ok, body}

      _ ->
        :error
    end
  end
end
