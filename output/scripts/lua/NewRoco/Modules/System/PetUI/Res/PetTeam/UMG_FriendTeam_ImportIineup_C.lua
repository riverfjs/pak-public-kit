local PetTeamUtils = require("NewRoco.Modules.System.PetUI.Res.PetTeam.PetTeamUtils")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local UMG_FriendTeam_ImportIineup_C = _G.NRCPanelBase:Extend("UMG_FriendTeam_ImportIineup_C")

function UMG_FriendTeam_ImportIineup_C:OnConstruct()
  self.data = self.module:GetData("PetUIModuleData")
  self:SetChildViews(self.PopUp2)
  self:OnAddEventListener()
  self:SetCommonPopUpInfo()
  self:LoadAnimation(0)
end

function UMG_FriendTeam_ImportIineup_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.ClosePanel
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp2:SetPanelInfo(CommonPopUpData)
end

function UMG_FriendTeam_ImportIineup_C:ClosePanel()
  self:LoadAnimation(2)
  _G.NRCAudioManager:PlaySound2DAuto(41400010, "UMG_MagicBook_C:ClosePanel")
end

function UMG_FriendTeam_ImportIineup_C:MirrorSuccessClose()
  self.IsMirrorSuccessClose = true
  self:DoClose()
end

function UMG_FriendTeam_ImportIineup_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    if self.IsMirrorSuccessClose then
    elseif self.module:HasPanel("FriendPetTeamDetailPanel") then
      self.module:EnablePanel("FriendPetTeamDetailPanel")
    end
    self:DoClose()
  elseif anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

function UMG_FriendTeam_ImportIineup_C:CheckHasBossItem()
  local IsBossBloodMagic = false
  local magicId = self.PetTeam.mirror_magic_id
  if magicId and magicId > 0 then
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(magicId)
    if BagItemConf and BagItemConf.player_skill_id and BagItemConf.player_skill_id > 0 then
      local playerMagicConf = _G.DataConfigManager:GetPlayerMagicConf(BagItemConf.player_skill_id)
      if playerMagicConf and playerMagicConf.skill_id and playerMagicConf.skill_id > 0 then
        local skillConf = _G.DataConfigManager:GetSkillConf(playerMagicConf.skill_id)
        if skillConf and skillConf.target_blood_limit and skillConf.target_blood_limit and 1 == #skillConf.target_blood_limit and skillConf.target_blood_limit[1] == Enum.PetBloodType.PBT_BOSS then
          IsBossBloodMagic = true
        end
      end
    end
  end
  if not IsBossBloodMagic then
    return true, ""
  end
  local PetName = {}
  for i, petInfo in ipairs(self.Mirror_pet_infos) do
    local PetData = self.data:GetPetDataByFriendUinAndPetGid(self.MirrorFromUin, petInfo.pet_gid)
    local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id, true)
    if PetData.blood_id == Enum.PetBloodType.PBT_BOSS and PetBaseConf and PetBaseConf.bosspetbase_rule == BattleEnum.BloodItemRule.BossPet and PetBaseConf.bosspetbase_rule_param and #PetBaseConf.bosspetbase_rule_param > 0 then
      local BagItem = _G.NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, PetBaseConf.bosspetbase_rule_param[1])
      if BagItem and BagItem.type == Enum.BagItemType.BI_BOSS_EVO and BagItem.num and BagItem.num > 0 then
      else
        local mirror_boss_evo_items = self.PetTeam and self.PetTeam.mirror_boss_evo_items
        local IsHasMirrorItem = false
        if mirror_boss_evo_items then
          for _, v in ipairs(mirror_boss_evo_items) do
            if v == PetBaseConf.bosspetbase_rule_param[1] then
              IsHasMirrorItem = true
              break
            end
          end
        end
        if not IsHasMirrorItem then
          table.insert(PetName, PetBaseConf and PetBaseConf.name)
        end
      end
    end
  end
  if PetName and #PetName > 0 then
    return false, table.concat(PetName, "\227\128\129")
  else
    return true, ""
  end
end

function UMG_FriendTeam_ImportIineup_C:OnActive(TeamType, MirrorTeamIndex, MirrorFromUin, PetTeam)
  _G.NRCAudioManager:PlaySound2DAuto(41400009, "UMG_MagicBook_C:ClosePanel")
  self.PetTeam = PetTeam
  self.Mirror_pet_infos = PetTeam and PetTeam.pet_infos
  self.MirrorFromUin = MirrorFromUin
  self.MirrorTeamIndex = MirrorTeamIndex
  self.TeamType = TeamType
  local IsMaxMirror
  if MirrorTeamIndex and MirrorFromUin then
    local curMirrorNum, MaxMirrorNum = PetTeamUtils.GetMirrorTeamNumByTeamType(TeamType)
    IsMaxMirror = MaxMirrorNum <= curMirrorNum
  end
  local teamInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(TeamType)
  self.curTeamInfo = teamInfo
  local petTeamList = {}
  self.TeamNum = #teamInfo.teams
  for i, v in ipairs(teamInfo.teams) do
    local petList = {}
    for j = 1, 6 do
      table.insert(petList, "nil")
    end
    if v.pet_infos then
      for index, PetTeamInfo in ipairs(v.pet_infos) do
        local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(PetTeamInfo.pet_gid, v.is_mirror)
        if not petData then
          Log.Error(PetTeamInfo.pet_gid, "@GID\231\188\186\229\176\145petdata")
          petList[index] = "nil"
        else
          local FriendTeamAvatarpData = {}
          FriendTeamAvatarpData.PetData = petData
          FriendTeamAvatarpData.isTrailPet = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, petData.gid)
          petList[index] = FriendTeamAvatarpData
        end
      end
    end
    local petTeam = {
      petList = petList,
      IsMaxMirror = IsMaxMirror,
      team = v,
      Panel = self
    }
    table.insert(petTeamList, petTeam)
  end
  self.LineupView:InitList(petTeamList)
  self:SetCommonPopUpInfo()
end

function UMG_FriendTeam_ImportIineup_C:TryCoverMirrorTeam(TeamIndex, IsEmptyTeam)
  self.selectTeamIndex = TeamIndex
  if IsEmptyTeam then
    self:TrySendMirrorTeamReq(true)
  else
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local dialogContext = DialogContext()
    dialogContext:SetContent(LuaText.share_pet_import_check):SetTitle(LuaText.TIPS):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true):SetCloseOnOK(true):SetClickAnywhereClose(true):SetCallback(self, self.TrySendMirrorTeamReq):SetToppingIconType(0)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, dialogContext)
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_FriendTeam_ImportIineup_C:TrySendMirrorTeamReq(Bool)
  if Bool then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SendZonePetTeamFriendMirrorReq, self.TeamType, self.selectTeamIndex - 1, self.MirrorFromUin, self.MirrorTeamIndex)
  else
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_FriendTeam_ImportIineup_C:UseRecommendTeam(teamIndex, IsEmptyTeam)
  self.teamIndex = teamIndex
  if IsEmptyTeam then
    self:ChangePVPTeam()
  else
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local dialogContext = DialogContext()
    dialogContext:SetContent(LuaText.weekend_challenge_11):SetTitle(LuaText.TIPS):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true):SetCloseOnOK(true):SetClickAnywhereClose(true):SetCallbackOkOnly(self, self.ChangePVPTeam):SetToppingIconType(0)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  end
end

function UMG_FriendTeam_ImportIineup_C:ChangePVPTeam()
  self:LoadAnimation(2)
  self:DispatchEvent(PetUIModuleEvent.OnShiningWeekendPetChangeClose, self.teamIndex)
end

function UMG_FriendTeam_ImportIineup_C:OnDeactive()
end

function UMG_FriendTeam_ImportIineup_C:OnAddEventListener()
end

return UMG_FriendTeam_ImportIineup_C
