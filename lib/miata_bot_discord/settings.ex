defmodule MiataBotDiscord.Settings do
  def build do
    %{
      verification_channel_id: nil,
      memes_channel_id: nil,
      general_channel_id: nil,
      offtopic_channel_id: nil,
      miata_fan_role_id: nil,
      looking_for_miata_role_id: nil,
      bot_spam_channel_id: nil,
      admin_role_id: nil,
      carinfo_channel_id: nil
    }
  end

  def main_server do
    create_settings(322_080_266_761_797_633, %{
      build()
      | admin_role_id: 322_155_210_741_121_026,
        bot_spam_channel_id: 351_767_273_712_910_336,
        carinfo_channel_id: 821_884_551_688_749_087,
        general_channel_id: 322_080_266_761_797_633,
        offtopic_channel_id: 322_162_421_156_282_369,
        looking_for_miata_role_id: 504_088_951_485_890_561,
        miata_fan_role_id: 439_493_557_301_280_789,
        memes_channel_id: 555_431_196_884_992_000,
        verification_channel_id: 322_127_502_212_333_570
    })
  end

  def create_settings(guild_id, attrs) do
    Quarrel.add_setting(
      guild_id,
      :verification_channel_id,
      Map.fetch!(attrs, :verification_channel_id)
    )

    Quarrel.add_setting(guild_id, :memes_channel_id, Map.fetch!(attrs, :memes_channel_id))
    Quarrel.add_setting(guild_id, :general_channel_id, Map.fetch!(attrs, :general_channel_id))
    Quarrel.add_setting(guild_id, :offtopic_channel_id, Map.fetch!(attrs, :offtopic_channel_id))
    Quarrel.add_setting(guild_id, :miata_fan_role_id, Map.fetch!(attrs, :miata_fan_role_id))

    Quarrel.add_setting(
      guild_id,
      :looking_for_miata_role_id,
      Map.fetch!(attrs, :looking_for_miata_role_id)
    )

    Quarrel.add_setting(guild_id, :bot_spam_channel_id, Map.fetch!(attrs, :bot_spam_channel_id))
    Quarrel.add_setting(guild_id, :admin_role_id, Map.fetch!(attrs, :admin_role_id))
    Quarrel.add_setting(guild_id, :carinfo_channel_id, Map.fetch!(attrs, :carinfo_channel_id))
  end
end
