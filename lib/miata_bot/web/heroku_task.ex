defmodule MiataBot.Web.HerokuTask do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    url = Keyword.fetch!(args, :url)
    {:ok, url, 5000}
  end

  def handle_info(:timeout, url) do
    _ = :httpc.request(:get, {'#{url}', []}, [], [])
    {:noreply, url, 15_000}
  end
end
