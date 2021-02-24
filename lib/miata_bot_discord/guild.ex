defmodule MiataBotDiscord.Guild do
  @moduledoc """
  Root level supervisor for every guild.
  Don't start manually - The Event source should use
  the dynamic supervisor to start this supervisor.
  """
  use Supervisor

  alias MiataBotDiscord.Guild.{
    BootmsgConsumer,
    AutoreplyConsumer,
    CarinfoConsumer,
    ChannelLimitsConsumer,
    LMGTFYConcumer,
    LookingForMiataConsumer,
    MemesChannelConsumer,
    EvalConsumer,
    HaHaBoteConsumer
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
      {ChannelLimitsConsumer, {guild, config, current_user}},
      {LMGTFYConcumer, {guild, config, current_user}},
      {LookingForMiataConsumer, {guild, config, current_user}},
      {MemesChannelConsumer, {guild, config, current_user}},
      {EvalConsumer, {guild, config, current_user}},

      # Workers
      {MiataBotDiscord.Guild.ChannelLimitsWorker, {guild, config, current_user}},
      {MiataBotDiscord.Guild.LookingForMiataWorker, {guild, config, current_user}},
      {MiataBotDiscord.Guild.CopyPastaWorker, {guild, config, current_user}},
      {HaHaBoteConsumer, {guild, config, current_user}},


      # Responder
      {MiataBotDiscord.Guild.Responder,
       {guild,
        [
          via(guild, BootmsgConsumer),
          via(guild, AutoreplyConsumer),
          via(guild, CarinfoConsumer),
          via(guild, ChannelLimitsConsumer),
          via(guild, LMGTFYConcumer),
          via(guild, LookingForMiataConsumer),
          via(guild, MemesChannelConsumer),
          via(guild, EvalConsumer),
          via(guild, HaHaBoteConsumer)
        ]}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
