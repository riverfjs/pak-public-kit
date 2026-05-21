local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local MusicCollectionUtils = {}

function MusicCollectionUtils.GetBgmStateGroupByApplyType(ApplyTypeEnum, applyType)
  local StateGroup = "UI_Music;None"
  if applyType == Enum.InterfaceType.IT_PET then
    StateGroup = "UI_Music;UI_Music;UI_Type;Pet_Interface"
  end
  if applyType == Enum.InterfaceType.IT_SEASON or applyType == Enum.InterfaceType.IT_BP then
    local seasonInfo = _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo)
    if seasonInfo then
      local seasonConf = _G.DataConfigManager:GetSeasonConf(seasonInfo.season_id)
      local bgm_state = seasonConf and seasonConf.bgm_state or ""
      if "" ~= bgm_state then
        _G.NRCAudioManager:SetStateByName("UI_Music", "UI_Music")
        _G.NRCAudioManager:SetStateByName("UI_Type", bgm_state)
        return
      end
    end
  end
  if applyType == Enum.InterfaceType.IT_CARD then
    local FriendModule = _G.NRCModuleManager:GetModule("FriendModule")
    if FriendModule and FriendModule.data then
      local CardAdminFriendType = FriendModule.data:GetCardAdminFriendType()
      if CardAdminFriendType == FriendEnum.AdminFriendType.Others then
        local PlayerCardBriefInfo = FriendModule.data:GetPlayerCardBriefInfo()
        if PlayerCardBriefInfo and PlayerCardBriefInfo.player_card_brief_info and PlayerCardBriefInfo.player_card_brief_info.card_music_id then
          local musicConf = _G.DataConfigManager:GetMusicConf(PlayerCardBriefInfo.player_card_brief_info.card_music_id)
          if musicConf then
            if musicConf.music_type == Enum.MusicType.MT_WEBGAME then
              StateGroup = "UI_Music;UI_Music;Music_Collect;Collect;UI_Type;None;Music_Collect_Type;Web;" .. musicConf.StateGroup_State
            elseif musicConf.music_type == Enum.MusicType.MT_MOBILE then
              StateGroup = "UI_Music;UI_Music;Music_Collect;Collect;UI_Type;None;Music_Collect_Type;Mobile;" .. musicConf.StateGroup_State
            end
            if StateGroup then
              _G.NRCAudioManager:BatchSetState(StateGroup)
              return
            end
          end
        end
      end
    end
  end
  local ApplyId
  local ApplyListConf = _G.DataConfigManager:GetAllByName("MUSIC_APPLY_LIST_CONF")
  for i, v in pairs(ApplyListConf) do
    if v.interface_type == applyType and v.list_type == ApplyTypeEnum then
      ApplyId = v.id
      break
    end
  end
  local playerInfo = _G.DataModelMgr.PlayerDataModel.playerInfo
  if playerInfo and playerInfo.music_info and playerInfo.music_info.apply_list then
    local ApplyList = playerInfo.music_info.apply_list
    for i, v in pairs(ApplyList) do
      if v.apply_list_id == ApplyId then
        local musicConf = _G.DataConfigManager:GetMusicConf(v.music_id)
        if musicConf.music_type == Enum.MusicType.MT_WEBGAME then
          StateGroup = "UI_Music;UI_Music;Music_Collect;Collect;UI_Type;None;Music_Collect_Type;Web;" .. musicConf.StateGroup_State
        elseif musicConf.music_type == Enum.MusicType.MT_MOBILE then
          StateGroup = "UI_Music;UI_Music;Music_Collect;Collect;UI_Type;None;Music_Collect_Type;Mobile;" .. musicConf.StateGroup_State
        end
      end
    end
  end
  return StateGroup
end

return MusicCollectionUtils
