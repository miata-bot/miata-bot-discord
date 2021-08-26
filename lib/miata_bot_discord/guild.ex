defmodule MiataBotDiscord.Guild do
  @moduledoc """
  Root level supervisor for every guild.
  Don't start manually - The Event source should use
  the dynamic supervisor to start this supervisor.

  connor - what does this even mean?
  """
  use Supervisor

  alias MiataBotDiscord.Guild.{
    BootmsgConsumer,
    AutoreplyConsumer,
    CarinfoConsumer,
    # Carinfo.AttachmentConsumer,
    # Carinfo.AttachmentCahe,
    InventoryConsumer,
    TradeConsumer,
    ChannelLimitsConsumer,
    LookingForMiataConsumer,
    MemesChannelConsumer
  }

  import MiataBotDiscord.Guild.Registry, only: [via: 2]

  def child_spec({guild, config, user}) do
    %{
      id: guild.id,
      start: {__MODULE__, :start_link, [{guild, config, user}]}
    }
  end

  @doc false
  def start_link({guild, config, current_user}) do
    Supervisor.start_link(__MODULE__, {guild, config, current_user})
  end

  @impl Supervisor
  def init({guild, config, current_user}) do
    children = [
      # boostrap processes
      {MiataBotDiscord.Guild.Registry, guild},
      {MiataBotDiscord.Guild.EventDispatcher, guild},

      # consumers
      {BootmsgConsumer, {guild, config, current_user}},
      {AutoreplyConsumer, {guild, config, current_user}},
      {CarinfoConsumer, {guild, config, current_user}},
      {InventoryConsumer, {guild, config, current_user}},
      {TradeConsumer, {guild, config, current_user}},
      {MiataBotDiscord.Guild.Carinfo.AttachmentConsumer, {guild, config, current_user}},
      {ChannelLimitsConsumer, {guild, config, current_user}},
      {LookingForMiataConsumer, {guild, config, current_user}},
      {MemesChannelConsumer, {guild, config, current_user}},

      # Workers
      {MiataBotDiscord.Guild.ChannelLimitsWorker, {guild, config, current_user}},
      {MiataBotDiscord.Guild.LookingForMiataWorker, {guild, config, current_user}},
      {MiataBotDiscord.Guild.CopyPastaWorker, {guild, config, current_user}},
      {MiataBotDiscord.Guild.Carinfo.AttachmentCache, {guild, config, current_user}},

      # Responder
      {MiataBotDiscord.Guild.Responder,
       {guild,
        [
          {via(guild, BootmsgConsumer), []},
          {via(guild, AutoreplyConsumer), []},
          {via(guild, CarinfoConsumer), []},
          {via(guild, InventoryConsumer), []},
          {via(guild, TradeConsumer), []},
          {via(guild, MiataBotDiscord.Guild.Carinfo.AttachmentConsumer), []},
          {via(guild, ChannelLimitsConsumer), []},
          {via(guild, LookingForMiataConsumer), []},
          {via(guild, MemesChannelConsumer), []}
        ]}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
