defmodule MiataBotDiscord.Guild.Carinfo.AttachmentCache do
  @moduledoc """
  Handles caching attachments for the carinfo command
  """
  import MiataBotDiscord.Guild.Registry, only: [via: 2]

  alias Nostrum.Struct.Message.Attachment
  defstruct []
  use GenServer

  def start_link({guild, config, current_user}) do
    GenServer.start_link(__MODULE__, {guild, config, current_user}, name: via(guild, __MODULE__))
  end

  @doc "Cache an attachment for a user"
  def cache_attachment(guild, discord_user_id, %Attachment{} = attachment) do
    GenServer.cast(via(guild, __MODULE__), {:cache_attachment, discord_user_id, attachment})
  end

  def fetch_attachment(guild, discord_user_id) do
    GenServer.call(via(guild, __MODULE__), {:fetch_attachment, discord_user_id})
  end

  @impl GenServer
  def init({_guild, _config, _current_user}) do
    table =
      :ets.new(Module.concat(__MODULE__, :__attachment_cache__), [
        :named_table,
        {:write_concurency, true},
        {:read_concurency, false},
        :ordered_set
      ])

    {:ok, %{table: table}}
  end

  @impl GenServer
  def handle_cast({:cache_attachment, discord_user_id, attachment}, state) do
    true = :ets.insert(state.table, {discord_user_id, attachment})
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:fetch_attachment, discord_user_id}, _from, state) do
    case :ets.lookup(state.table, discord_user_id) do
      [attachment] -> {:reply, attachment, state}
      [] -> {:reply, nil, state}
    end
  end
end
