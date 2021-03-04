defmodule Webdriver do
  use GenServer

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def screenshot(pid \\ __MODULE__, url) do
    GenServer.call(pid, {:screenshot, url}, 10_000)
  end

  def init(_) do
    send(self(), :open_port)
    {:ok, %{port: nil, caller: nil}}
  end

  def handle_info(:open_port, state) do
    python = System.find_executable("python3")
    script = Application.app_dir(:miata_bot, ["priv", "test.py"])
    # script = "/home/connor/workspace/sixtyeightplus.one/miata_bot/test.py"

    port =
      :erlang.open_port({:spawn_executable, python}, [
        :binary,
        {:packet, 4},
        {:args, ["-u", script]},
        :nouse_stdio
      ])

    {:noreply, %{state | port: port}}
  end

  def handle_info({port, {:data, data}}, %{port: port, caller: caller} = state) do
    GenServer.reply(caller, {:ok, :erlang.binary_to_term(data)})
    {:noreply, %{state | caller: nil}}
  end

  def handle_call({:screenshot, url}, from, %{port: port} = state) do
    true = :erlang.port_command(port, :erlang.term_to_binary(url))
    {:noreply, %{state | caller: from}}
  end
end
