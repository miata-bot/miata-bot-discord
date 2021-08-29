defmodule MiataBotDiscord.SettingsListener do
  require Logger
  use Quarrel.Listener

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl Quarrel.Listener
  def handle_guild_available(guild, state) do
    if Enum.empty?(state.config) do
      Logger.warn("Creating empty settings for Guild #{guild.id}")

      for {setting, _} <- MiataBotDiscord.Settings.build() do
        Quarrel.add_setting(guild, setting, nil)
      end

      Logger.warn("Installing interactions to new build")
      Quarrel.Interactions.install(guild, MiataBotDiscord.Interactions.interactions())
    end

    {:noreply, state}
  end
end
