defmodule MiataBotWeb.HerokuTask do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    args = Keyword.merge(Application.get_env(:miata_bot, __MODULE__, []), args)
    url = Keyword.fetch!(args, :url)
    {:ok, url, 5000}
  end

  def handle_info(:timeout, url) do
    _ = :httpc.request(:get, {'#{url}', []}, [], [])
    {:noreply, url, 600_000}
  end
end
