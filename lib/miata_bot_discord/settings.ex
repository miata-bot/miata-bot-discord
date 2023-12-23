defmodule MiataBotDiscord.Settings do
  def build do
    %{
      verification_channel_id: nil,
      memes_channel_id: nil,
      general_channel_id: nil,
      offtopic_channel_id: nil,
      accepted_role_id: nil,
      looking_for_miata_role_id: nil,
      bot_spam_channel_id: nil,
      admin_role_id: nil,
      carinfo_channel_id: nil,
      tcg_channel_id: nil
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
        accepted_role_id: 322_458_363_700_969_482,
        memes_channel_id: 555_431_196_884_992_000,
        verification_channel_id: 322_127_502_212_333_570,
        tcg_channel_id: nil
    })
  end

  def secondary_server do
    create_settings(643_947_339_895_013_416, %{
      build()
      | admin_role_id: 643_958_189_460_553_729,
        bot_spam_channel_id: 778_353_870_593_982_485,
        carinfo_channel_id: 822_114_165_841_068_102,
        general_channel_id: 778_334_280_337_719_357,
        offtopic_channel_id: 778_334_306_002_927_646,
        looking_for_miata_role_id: 778_340_553_460_285_461,
        accepted_role_id: 992_581_401_402_675_224,
        memes_channel_id: 778_325_951_989_284_894,
        verification_channel_id: 778_325_814_986_014_731,
        tcg_channel_id: 883_408_087_598_391_376
    })
  end

  def dev_server do
    create_settings(865_257_998_691_991_572, %{
      build()
      | admin_role_id: 905_841_646_380_396_604,
        bot_spam_channel_id: 865_257_998_691_991_575,
        carinfo_channel_id: 865_257_998_691_991_575,
        general_channel_id: 865_257_998_691_991_575,
        offtopic_channel_id: 865_257_998_691_991_575,
        looking_for_miata_role_id: 905_841_855_554_519_101,
        accepted_role_id: 591_899_819_132_583_936,
        memes_channel_id: 865_257_998_691_991_575,
        verification_channel_id: 865_257_998_691_991_575,
        tcg_channel_id: 865_257_998_691_991_575
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
    Quarrel.add_setting(guild_id, :accepted_role_id, Map.fetch!(attrs, :accepted_role_id))

    Quarrel.add_setting(
      guild_id,
      :looking_for_miata_role_id,
      Map.fetch!(attrs, :looking_for_miata_role_id)
    )

    Quarrel.add_setting(guild_id, :bot_spam_channel_id, Map.fetch!(attrs, :bot_spam_channel_id))
    Quarrel.add_setting(guild_id, :admin_role_id, Map.fetch!(attrs, :admin_role_id))
    Quarrel.add_setting(guild_id, :carinfo_channel_id, Map.fetch!(attrs, :carinfo_channel_id))
    Quarrel.add_setting(guild_id, :tcg_channel_id, Map.fetch!(attrs, :tcg_channel_id))
  end
end
