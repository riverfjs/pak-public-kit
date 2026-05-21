local WeeklyChallengeBattleModule = NRCModuleBase:Extend("WeeklyChallengeBattleModule")
local WeeklyChallengeBattleModuleEnum = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEnum")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local WeeklyChallengeBattleModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")

function WeeklyChallengeBattleModule:OnConstruct()
  _G.WeeklyChallengeBattleModuleCmd = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleCmd")
  self.data = self:SetData("WeeklyChallengeBattleModuleData", "NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleData")
  self:RegPanel("WeeklyChallengeSettlement", "UMG_ChallengeSettlement", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("StarlightPhoto", "UMG_WeeklyChallengeBattle_StarlightReview", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, true, false, true)
  self:AddEventListener()
  self:RegPanel("StarlightShowDown", "UMG_StarlightShowdownPanel", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, true, false, true)
  self:RegPanel("TeamEdit", "UMG_FormationPanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true, false, true)
  self:RegPanel("RewardClaim", "UMG_ClaimReward", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true, false, true)
  self:RegPanel("FirstDebutPetChoose", "UMG_FirstReleasePanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true, false, true)
  self:RegPanel("PetDetail", "UMG_ChangePetConfirmPanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true, false, true)
  self:RegPanel("ResetNotification", "UMG_CultivationResetTips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true, false, true)
  self:RegPanel("BlackBar", "UMG_BlackBar", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true, false, true)
  self:RegPanel("ChangePanelCurtain", "UMG_WeeklyChallengeBattle_Curtain", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("ChangePanelEffect", "UMG_ExcessiveAnimationEffects", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("CheerUpPointTips", "UMG_PetCheer_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true, false, true)
  self.DontDisablePanelList = {}
  self.npcAction = nil
  self.bCanClearBgm = true
end

function WeeklyChallengeBattleModule:RegPanel(name, path, layer, OpenAnimName, CloseAnimName, isSingleTouchPanel, customDisableRendering, enablePcEsc)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/WeeklyChallengeBattle/Res/%s", path)
  registerData.panelLayer = layer
  registerData.openAnimName = OpenAnimName
  registerData.closeAnimName = CloseAnimName
  registerData.isSingleTouchPanel = isSingleTouchPanel
  registerData.customDisableRendering = customDisableRendering or false
  if nil == enablePcEsc then
    enablePcEsc = false
  end
  registerData.enablePcEsc = enablePcEsc
  self:RegisterPanel(registerData)
end

function WeeklyChallengeBattleModule:AddEventListener()
  _G.NRCEventCenter:RegisterEvent("WeeklyChallengeBattleModule", self, WeeklyChallengeBattleModuleEvent.CloseLoadingCurtainEvent, self.OnCloseLoadingCurtainEvent)
  _G.NRCEventCenter:RegisterEvent("WeeklyChallengeBattleModule", self, PetUIModuleEvent.PetTeamEquipPetMagicRsp, self.OnPetTeamEquipPetMagicRsp)
  _G.NRCEventCenter:RegisterEvent("WeeklyChallengeBattleModule", self, WeeklyChallengeBattleModuleEvent.EntryHudSkillStartPlayerEvent, self.OnCmdClearWeeklyChallengeLevelSequencePlayer)
  _G.NRCEventCenter:RegisterEvent("WeeklyChallengeBattleModule", self, WeeklyChallengeBattleModuleEvent.OnActivityUpdate, self.OnActivityUpdate)
  _G.NRCEventCenter:RegisterEvent("WeeklyChallengeBattleModule", self, PetUIModuleEvent.RefreshAdjustPetPanel, self.OnPetAdjust)
  _G.NRCEventCenter:RegisterEvent("WeeklyChallengeBattleModule", self, SceneEvent.OnPreTeleportNotify, self.OnPreTeleportNotify)
end

function WeeklyChallengeBattleModule:OnCloseLoadingCurtainEvent(shouldOpenCameraEffect)
  self:ClearBgm()
  _G.NRCModuleManager:DoCmd(_G.LevelSelectionModuleCmd.CloseLoadingCurtain)
  if shouldOpenCameraEffect then
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenEffectPopup, nil, nil)
  end
end

function WeeklyChallengeBattleModule:OnPetTeamEquipPetMagicRsp(mainTeamIndex)
  local currentTeamInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(_G.Enum.PlayerTeamType.PTT_PVE_WEEKLY_CHALLENGE_FIGHT)
  self.data.CurrentTeamSkill = 0
  if currentTeamInfo and currentTeamInfo.teams and currentTeamInfo.teams[mainTeamIndex + 1] then
    self.data.CurrentTeamSkill = currentTeamInfo.teams[mainTeamIndex + 1].role_magic_gid
  end
end

function WeeklyChallengeBattleModule:OnPetAdjust()
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not WeeklyChallengeEventActivityObject or not WeeklyChallengeEventActivityObject[1] then
    Log.Error("WeeklyChallengeBattleModule:OnZonePetTeamChangeRsp \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
    return
  end
  local weekly_challenge_data = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  if not weekly_challenge_data then
    Log.Error("WeeklyChallengeBattleModule:OnZonePetTeamChangeRsp \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
    return
  end
  local activityId = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeActivityId()
  local challengeId = weekly_challenge_data.challenge_info.challenge_id
  self:OnCmdResetPetStateReq(activityId, challengeId)
end

function WeeklyChallengeBattleModule:RemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.CloseLoadingCurtainEvent, self.OnCloseLoadingCurtainEvent)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PetTeamEquipPetMagicRsp, self.OnPetTeamEquipPetMagicRsp)
  _G.NRCEventCenter:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnActivityUpdate, self.OnActivityUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.RefreshAdjustPetPanel, self.OnPetAdjust)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnPreTeleportNotify, self.OnPreTeleportNotify)
end

function WeeklyChallengeBattleModule:OnReLoginUpdate()
end

function WeeklyChallengeBattleModule:OnActivityUpdate()
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not WeeklyChallengeEventActivityObject or not WeeklyChallengeEventActivityObject[1] then
    return
  end
  local newActivityId = WeeklyChallengeEventActivityObject[1]:GetActivityId()
  if newActivityId ~= self.data.currentActivityId then
    self:DispatchEvent(WeeklyChallengeBattleModuleEvent.OnActivityEventIdChanged)
  end
  self:UpdateAllCachedPetSkillsFromActivityData()
end

function WeeklyChallengeBattleModule:UpdateAllCachedPetSkillsFromActivityData()
  if not self.data.AllPetBalancedDataMap then
    return
  end
  local equipSkillsMap = self:GetEquipSkillsMapFromActivityData()
  for gid, petData in pairs(self.data.AllPetBalancedDataMap) do
    if petData and petData.skill and petData.skill.skill_data then
      local savedEquipInfos = equipSkillsMap[gid]
      if savedEquipInfos and #savedEquipInfos > 0 then
        for _, skillData in ipairs(petData.skill.skill_data) do
          skillData.is_equipped = false
          skillData.pos = 0
        end
        local savedEquipMap = {}
        for _, equipInfo in ipairs(savedEquipInfos) do
          if equipInfo.id and equipInfo.pos then
            savedEquipMap[equipInfo.id] = equipInfo.pos
          end
        end
        for _, skillData in ipairs(petData.skill.skill_data) do
          local savedPos = savedEquipMap[skillData.id]
          if savedPos then
            skillData.is_equipped = true
            skillData.pos = savedPos
          end
        end
        Log.Info(string.format("WeeklyChallengeBattleModule:UpdateAllCachedPetSkillsFromActivityData Updated pet gid: %d with %d equipped skills", gid, #savedEquipInfos))
      end
    end
  end
end

function WeeklyChallengeBattleModule:OnPlayerDataUpdate()
end

function WeeklyChallengeBattleModule:OnActive()
end

function WeeklyChallengeBattleModule:OnRelogin()
end

function WeeklyChallengeBattleModule:OnDeactive()
end

function WeeklyChallengeBattleModule:OnDestruct()
end

function WeeklyChallengeBattleModule:AfterAnimBattleAgain(activity_id, challenge_id, priority_pet_gid)
end

function WeeklyChallengeBattleModule:OnWeeklyChallengeBattleAgain(activity_id, challenge_id, priority_pet_gid)
  self:OnSetWeeklyChallengeBattleAgain(true)
  self.activity_id = activity_id
  self.challenge_id = challenge_id
  self.priority_pet_gid = priority_pet_gid
  _G.NRCModuleManager:DoCmd(_G.LevelSelectionModuleCmd.OpenLoadingCurtain, self, function(caller)
    _G.BattleEventCenter:Dispatch(BattleEvent.WEEKLY_CHALLENGE_AGAIN)
  end)
end

function WeeklyChallengeBattleModule:OnWeeklyChallengeBattleAgainRsp(rsp)
  if rsp.ret_info and rsp.ret_info.ret_code and 0 == rsp.ret_info.ret_code then
  elseif rsp.ban_info and rsp.ban_info.ban_reason then
    Log.Error("\229\138\159\232\131\189\229\176\129\231\166\129\228\184\173:", rsp.ban_info.ban_reason)
    _G.NRCModuleManager:DoCmd(_G.LevelSelectionModuleCmd.CloseLoadingCurtain)
    _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.HIDE_ALL, false)
  end
end

function WeeklyChallengeBattleModule:OnCmdSendWeeklyChallengeBattleAgain()
  if not self.activity_id or not self.challenge_id then
    return
  end
  local req = self:GetWeeklyChallengeCreateBattleReq(self.activity_id, self.challenge_id, self.priority_pet_gid)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_WEEKLY_CHALLENGE_CREATE_BATTLE_REQ, req, self, self.OnWeeklyChallengeBattleAgainRsp, false, false)
end

function WeeklyChallengeBattleModule:OnIsWeeklyChallengeBattleAgain()
  return self.isChallengeAgain, self.lastPlayerPos
end

function WeeklyChallengeBattleModule:OnSetWeeklyChallengeBattleAgain(State)
  self.isChallengeAgain = State
  self.lastPlayerPos = _G.BattleManager.TeleportBackPos
end

function WeeklyChallengeBattleModule:GetWeeklyChallengeCreateBattleReq(activity_id, challenge_id, priority_pet_gid)
  local req = ProtoMessage:newZoneWeeklyChallengeCreateBattleReq()
  req.activity_id = activity_id or 4001
  req.challenge_id = challenge_id or 1000
  req.source_type = _G.ProtoEnum.EClientBattleSourceType.ECBST_WEEKLY_CHALLENGE
  if priority_pet_gid then
    req.priority_pet_gid = priority_pet_gid
  end
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    req.avatar_pt = localPlayer:GetServerPoint()
  end
  return req
end

function WeeklyChallengeBattleModule:OnSendZoneWeeklyChallengeCreateBattleReq(activity_id, challenge_id, priority_pet_gid)
  local req = self:GetWeeklyChallengeCreateBattleReq(activity_id, challenge_id, priority_pet_gid)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_WEEKLY_CHALLENGE_CREATE_BATTLE_REQ, req, self, self.OnZoneWeeklyChallengeCreateBattleRsp, false, false)
end

function WeeklyChallengeBattleModule:OnZoneWeeklyChallengeCreateBattleRsp(rsp)
  Log.Debug("OnZoneWeeklyChallengeCreateBattleRsp", rsp.ret_info.ret_code)
  if 0 == rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.ClosePhotoPanel)
  end
end

function WeeklyChallengeBattleModule:OnGetWeeklyChallengeDataTargetPoint()
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  local weekly_challenge_data
  if WeeklyChallengeEventActivityObject and WeeklyChallengeEventActivityObject[1] then
    weekly_challenge_data = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  end
  local answer = 0
  if weekly_challenge_data then
    answer = MagicManualUtils.GetWeeklyChallengeStarNum(weekly_challenge_data)
  end
  return answer
end

function WeeklyChallengeBattleModule:OnOpenWeeklyChallengeSettlement(...)
  self:OpenPanel("WeeklyChallengeSettlement", ...)
end

function WeeklyChallengeBattleModule:OnCloseWeeklyChallengeSettlement()
  local panel = self:HasPanel("WeeklyChallengeSettlement")
  if panel then
    self:ClosePanel("WeeklyChallengeSettlement")
  end
end

function WeeklyChallengeBattleModule:OnCmdTryOpenPhotoUmg()
  _G.NRCEventCenter:RegisterEvent("PVPRankedMatchModule", self, _G.WorldCombatModuleEvent.OnBattleRealEnd, self.OnOpenPhotoUmg)
end

function WeeklyChallengeBattleModule:OnOpenPhotoUmg()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.WorldCombatModuleEvent.OnBattleRealEnd, self.OnOpenPhotoUmg)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenStarlightPhoto, nil, 3)
end

function WeeklyChallengeBattleModule:OnCmdTryOpenStarlightUmg()
  _G.NRCEventCenter:RegisterEvent("PVPRankedMatchModule", self, _G.WorldCombatModuleEvent.OnBattleRealEnd, self.OnOpenStarlightUmg)
end

function WeeklyChallengeBattleModule:TipsOpenStarlightUmgAndReward()
  local IsUnLock = false
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if WeeklyChallengeEventActivityObject and WeeklyChallengeEventActivityObject[1] then
    local weekly_challenge_data = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
    if weekly_challenge_data then
      IsUnLock = true
    end
  end
  if IsUnLock then
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenStarlightPhoto, nil, 0, true)
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.cannot_jump_to_star_PVE)
  end
end

function WeeklyChallengeBattleModule:OnOpenStarlightUmg()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.WorldCombatModuleEvent.OnBattleRealEnd, self.OnOpenStarlightUmg)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenStarlightPhoto, nil, 0)
end

function WeeklyChallengeBattleModule:OpenStarlightPhoto(npcAction, panelType, NeedOpenReward)
  local ResListData = self:OnLoadPhotoPanelRes()
  local bIsOpening, _ = self:HasPanel("StarlightPhoto")
  if bIsOpening then
    return
  end
  local type
  if nil == panelType then
    type = 3
  else
    type = panelType
  end
  _G.NRCModuleManager:DoCmd(_G.LevelSelectionModuleCmd.OpenLoadingCurtain, nil, function()
    self:OpenPanel("StarlightPhoto", npcAction, type, NeedOpenReward, ResListData)
  end)
end

function WeeklyChallengeBattleModule:OnCmdOpenStarlightReviewPanel()
  local bIsOpening, _ = self:HasPanel("StarlightReview")
  if bIsOpening then
    return
  end
  self:OpenPanel("StarlightReview", 0)
end

function WeeklyChallengeBattleModule:OnCmdOpenCurtainPopup(caller, callback)
  local bIsOpening, _ = self:HasPanel("ChangePanelCurtain")
  if bIsOpening then
    return
  end
  self:OpenPanel("ChangePanelCurtain", caller, callback)
end

function WeeklyChallengeBattleModule:OnCmdCloseCurtainPopup()
  local bIsOpening, _ = self:HasPanel("ChangePanelCurtain")
  if not bIsOpening then
    return
  end
  local panel = self:GetPanel("ChangePanelCurtain")
  if panel then
    panel:TryClose()
  end
end

function WeeklyChallengeBattleModule:OnCmdOpenEffectPopup(caller, callback)
  local bIsOpening, _ = self:HasPanel("ChangePanelEffect")
  if bIsOpening then
    return
  end
  self:OpenPanel("ChangePanelEffect", caller, callback)
end

function WeeklyChallengeBattleModule:OnCmdCloseEffectPopup()
  local bIsOpening, _ = self:HasPanel("ChangePanelEffect")
  if not bIsOpening then
    return
  end
  local panel = self:GetPanel("ChangePanelEffect")
  if panel then
    panel:TryClose()
  end
end

function WeeklyChallengeBattleModule:OnCmdOpenBlackBar()
  local bIsOpening, _ = self:HasPanel("BlackBar")
  if bIsOpening then
    return
  end
  self:OpenPanel("BlackBar")
end

function WeeklyChallengeBattleModule:OnCmdCloseBlackBar()
  self:ClosePanel("BlackBar")
end

function WeeklyChallengeBattleModule:OnCmdOpenStarlightShowdownPanel()
  local bIsOpening, _ = self:HasPanel("StarlightShowDown")
  if bIsOpening then
    return
  end
  self:OpenPanel("StarlightShowDown")
end

function WeeklyChallengeBattleModule:OnCmdOpenTeamEditPanel(bFromPetHead)
  local bIsOpening, _ = self:HasPanel("TeamEdit")
  if bIsOpening then
    return
  end
  self:OpenPanel("TeamEdit", bFromPetHead)
end

function WeeklyChallengeBattleModule:OnCmdGetCurrentTeamPetList()
  return self.data:GetCurrentTeamPetList()
end

function WeeklyChallengeBattleModule:OnCmdAddPetToTeam(petData, position, bIgnoreSave)
  local petTeams = self.data:GetCurrentTeamPetList()
  for k, v in ipairs(petTeams) do
    if petData.gid == v.gid and v.gid and 0 ~= v.gid then
      Log.Error("WeeklyChallengeBattleModule:OnCmdAddPetToTeam \229\176\157\232\175\149\229\144\145\233\152\159\228\188\141\229\138\160\229\133\165\233\135\141\229\164\141\231\154\132\229\174\160\231\137\169")
      return
    end
  end
  self.data:AddPetToTeam(petData, position)
  self.bIsTeamDirty = true
  if not bIgnoreSave then
    self:OnCmdSendSaveTeamReq()
  end
end

function WeeklyChallengeBattleModule:OnCmdAddPetToFirstEmptySlot(petData, bIgnoreSave)
  local index = 0
  for k, v in ipairs(self.data:GetCurrentTeamPetList()) do
    if not v.gid or v.gid and 0 == v.gid then
      index = k
      break
    end
  end
  if 0 ~= index then
    self:OnCmdAddPetToTeam(petData, index, bIgnoreSave)
  end
  return index
end

function WeeklyChallengeBattleModule:OnCmdReplacePetByNewPetData(petData, position, bIgnoreSave)
  local teamList = self.data:GetCurrentTeamPetList()
  if teamList and teamList[position] and teamList[position].gid and 0 ~= teamList[position].gid then
    self:OnCmdRemovePetFromTeam(teamList[position].gid, true)
  end
  self:OnCmdAddPetToTeam(petData, position, bIgnoreSave)
end

function WeeklyChallengeBattleModule:OnCmdSwapTeamPetPosition(position1, position2)
  if position1 < 1 or position1 > 6 then
    return
  end
  if position2 < 1 or position2 > 6 then
    return
  end
  local teamList = self.data:GetCurrentTeamPetList()
  local temp = teamList[position1]
  teamList[position1] = teamList[position2]
  teamList[position2] = temp
  self.bIsTeamDirty = true
  self:OnCmdSendSaveTeamReq()
end

function WeeklyChallengeBattleModule:OnCmdRemovePetFromTeam(petGid, bIgnoreSave)
  self.data:RemovePetFromTeam(petGid)
  self.bIsTeamDirty = true
  if not bIgnoreSave then
    self:OnCmdSendSaveTeamReq()
  end
end

function WeeklyChallengeBattleModule:OnCmdClearTeam(bIgnoreSave)
  self.data.CurrentTeamPetList = {
    {},
    {},
    {},
    {},
    {},
    {}
  }
  self.FirstDebutPet = {}
  self.bIsTeamDirty = true
  if not bIgnoreSave then
    self:OnCmdSendSaveTeamReq()
  end
end

function WeeklyChallengeBattleModule:OnCmdDetailExchangeButtonClick()
  local bIsOpening, _ = self:HasPanel("TeamEdit")
  if bIsOpening then
    local panel = self:GetPanel("TeamEdit")
    if panel then
      panel:OnClickExchangeButton()
      return panel.bIsSwapMode
    end
  end
  return false
end

function WeeklyChallengeBattleModule:OnCmdPetChangeSkill(changes)
  local bIsOpening, _ = self:HasPanel("PetDetail")
  if bIsOpening then
    local panel = self:GetPanel("PetDetail")
    if panel then
      panel:OnEquippedSuccess(changes)
    end
  end
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not WeeklyChallengeEventActivityObject or not WeeklyChallengeEventActivityObject[1] then
    Log.Error("WeeklyChallengeBattleModule:OnCmdPetChangeSkill \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
    return
  end
  local weekly_challenge_data = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  if not weekly_challenge_data then
    Log.Error("WeeklyChallengeBattleModule:OnCmdPetChangeSkill \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
    return
  end
  local activityId = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeActivityId()
  local challengeId = weekly_challenge_data.challenge_info.challenge_id
  self:OnCmdResetPetStateReq(activityId, challengeId)
end

function WeeklyChallengeBattleModule:OnCmdEquipPetSkills(petGid, skillIds)
  self._pendingEquipPetGid = petGid
  self._pendingEquipSkillIds = skillIds
  local req = _G.ProtoMessage:newZonePetEquipSkillReq()
  req.team_type = _G.Enum.PlayerTeamType.PTT_PVE_WEEKLY_CHALLENGE_FIGHT
  req.gid = petGid
  req.equip_info = {}
  for index, skillId in ipairs(skillIds) do
    table.insert(req.equip_info, {id = skillId, pos = index})
  end
  Log.Info(string.format("WeeklyChallengeBattleModule:OnCmdEquipPetSkills \232\163\133\229\164\135\230\138\128\232\131\189. PetGid: %s, Skills: %s", tostring(petGid), table.concat(skillIds, ", ")))
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_EQUIP_SKILL_REQ, req, self, self.OnEquipPetSkillsRsp, false, false)
end

function WeeklyChallengeBattleModule:UpdatePetResetInfoSkills(petGid, skillIds)
  if not self.data.AllPetBalancedDataMap then
    return
  end
  local petData = self.data.AllPetBalancedDataMap[petGid]
  if not petData then
    Log.Warning(string.format("WeeklyChallengeBattleModule:UpdatePetResetInfoSkills \230\137\190\228\184\141\229\136\176\231\178\190\231\129\181\233\135\141\231\189\174\230\149\176\230\141\174. PetGid: %s", tostring(petGid)))
    return
  end
  if self.data.bIsNeedBalance and petData.skill and petData.skill.skill_data then
    local selectedSkillPosMap = {}
    for pos, skillId in ipairs(skillIds) do
      selectedSkillPosMap[skillId] = pos
    end
    for _, skillData in ipairs(petData.skill.skill_data) do
      local pos = selectedSkillPosMap[skillData.id]
      if pos then
        skillData.is_equipped = true
        skillData.pos = pos
      else
        skillData.is_equipped = false
        skillData.pos = 0
      end
    end
    Log.Info(string.format("WeeklyChallengeBattleModule:UpdatePetResetInfoSkills \230\155\180\230\150\176AllPetBalancedDataMap\231\188\147\229\173\152\230\138\128\232\131\189. PetGid: %s", tostring(petGid)))
  end
end

function WeeklyChallengeBattleModule:OnEquipPetSkillsRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("\230\152\159\229\133\137\229\175\185\229\134\179\232\163\133\229\164\135\230\138\128\232\131\189\229\164\177\232\180\165")
    return
  end
  Log.Info("WeeklyChallengeBattleModule:OnEquipPetSkillsRsp \232\163\133\229\164\135\230\138\128\232\131\189\230\136\144\229\138\159")
  if self._pendingEquipPetGid and self._pendingEquipSkillIds then
    self:UpdatePetResetInfoSkills(self._pendingEquipPetGid, self._pendingEquipSkillIds)
    self._pendingEquipPetGid = nil
    self._pendingEquipSkillIds = nil
  end
  self:DispatchEvent(WeeklyChallengeBattleModuleEvent.OnPetSkillChanged)
  _G.NRCEventCenter:DispatchEvent(WeeklyChallengeBattleModuleEvent.OnPetSkillChanged)
end

function WeeklyChallengeBattleModule:OnCmdUpdatePetCollect(partner_mark)
  self:DispatchEvent(WeeklyChallengeBattleModuleEvent.UpdatePetCollect, partner_mark)
end

function WeeklyChallengeBattleModule:OnCmdSendSaveTeamReq()
  local team = _G.ProtoMessage:newPetTeam()
  team.role_magic_gid = self.data:GetCurrentTeamSkill()
  team.team_name = "wcbt"
  team.pet_infos = {}
  local added_gids = {}
  for k, v in ipairs(self.data:GetCurrentTeamPetList()) do
    if v and v.gid and 0 ~= v.gid and not added_gids[v.gid] then
      table.insert(team.pet_infos, {
        pet_gid = v.gid
      })
      added_gids[v.gid] = true
    end
  end
  local req = _G.ProtoMessage:newZonePetTeamChangeReq()
  req.team_type = _G.Enum.PlayerTeamType.PTT_PVE_WEEKLY_CHALLENGE_FIGHT
  req.team_idxs = {}
  table.insert(req.team_idxs, 0)
  req.teams = {}
  table.insert(req.teams, team)
  local pet_gids_for_log = {}
  for _, pet_info in ipairs(team.pet_infos) do
    table.insert(pet_gids_for_log, tostring(pet_info.pet_gid))
  end
  local log_message = string.format("WeeklyChallengeBattleModule:OnCmdSendSaveTeamReq \228\191\157\229\173\152\231\188\150\233\152\159. \230\138\128\232\131\189GID: %s, \229\174\160\231\137\169GIDs: [%s]", tostring(team.role_magic_gid), table.concat(pet_gids_for_log, ", "))
  Log.Info(log_message)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_CHANGE_REQ, req, self, self.OnZonePetTeamChangeRsp, false, false)
end

function WeeklyChallengeBattleModule:OnZonePetTeamChangeRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("\230\152\159\229\133\137\229\175\185\229\134\179\231\188\150\233\152\159\228\191\157\229\173\152\229\164\177\232\180\165")
    return
  end
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not WeeklyChallengeEventActivityObject or not WeeklyChallengeEventActivityObject[1] then
    Log.Error("WeeklyChallengeBattleModule:OnZonePetTeamChangeRsp \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
    return
  end
  local weekly_challenge_data = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  if not weekly_challenge_data then
    Log.Error("WeeklyChallengeBattleModule:OnZonePetTeamChangeRsp \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
    return
  end
  local activityId = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeActivityId()
  local challengeId = weekly_challenge_data.challenge_info.challenge_id
  self:OnCmdResetPetStateReq(activityId, challengeId)
  self.data:RefetchTeamList()
  self.bIsTeamDirty = false
  self:DispatchEvent(WeeklyChallengeBattleModuleEvent.OnTeamPetChanged, self.data.CurrentTeamPetList)
end

function WeeklyChallengeBattleModule:OnCmdCloseTeamEditPanel()
  local bIsOpening, _ = self:HasPanel("StarlightShowDown")
  if bIsOpening then
    local panel = self:GetPanel("StarlightShowDown")
    if panel then
      panel:OnTeamEditPanelClosed()
    end
  end
end

function WeeklyChallengeBattleModule:OnCmdCloseFormationPanel()
  local bIsOpening, _ = self:HasPanel("TeamEdit")
  if bIsOpening then
    local panel = self:GetPanel("TeamEdit")
    panel:OnClickCloseButton()
  end
end

function WeeklyChallengeBattleModule:OnUpdatePetData(newPetData)
  local bIsOpening, _ = self:HasPanel("StarlightShowDown")
  if bIsOpening then
    local panel = self:GetPanel("StarlightShowDown")
    if panel then
      panel:OnPetDataUpdate(newPetData)
    end
  end
  bIsOpening, _ = self:HasPanel("TeamEdit")
  if bIsOpening then
    local panel = self:GetPanel("TeamEdit")
    if panel then
      panel:OnPetDataUpdate(newPetData)
    end
  end
  bIsOpening, _ = self:HasPanel("PetDetail")
  if bIsOpening then
    local panel = self:GetPanel("PetDetail")
    if panel then
      panel:OnPetDataUpdate(newPetData)
    end
  end
  local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(newPetData.gid)
  self.data:UpdatePetData(petData)
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not WeeklyChallengeEventActivityObject or not WeeklyChallengeEventActivityObject[1] then
    Log.Error("WeeklyChallengeBattleModule:OnZonePetTeamChangeRsp \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
    return
  end
  local weekly_challenge_data = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  if not weekly_challenge_data then
    Log.Error("WeeklyChallengeBattleModule:OnZonePetTeamChangeRsp \232\142\183\229\143\150\230\180\187\229\138\168Object\229\164\177\232\180\165")
    return
  end
  local activityId = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeActivityId()
  local challengeId = weekly_challenge_data.challenge_info.challenge_id
  self:OnCmdResetPetStateReq(activityId, challengeId)
end

function WeeklyChallengeBattleModule:OnCmdOpenSkillPanel(petInfo, needBtn, needSkillPanel, bDirectToSkill)
  local bIsOpening, _ = self:HasPanel("PetDetail")
  if bIsOpening then
    return
  end
  self:OpenPanel("PetDetail", petInfo, needBtn, needSkillPanel, bDirectToSkill)
end

function WeeklyChallengeBattleModule:GetCurrentEventRewardList()
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not WeeklyChallengeEventActivityObject or not WeeklyChallengeEventActivityObject[1] then
    return {}
  end
  local weeklyChallengeData = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  local finishedStarNum = weeklyChallengeData and weeklyChallengeData.challenge_info and weeklyChallengeData.challenge_info.highest_cheer_point or 0
  local rewardList = {}
  if weeklyChallengeData and weeklyChallengeData.rewards and #weeklyChallengeData.rewards > 0 then
    for k, v in ipairs(weeklyChallengeData.rewards) do
      local rewardConf = _G.DataConfigManager:GetRewardConf(v.reward_id, true)
      if rewardConf then
        if rewardConf.RewardItem[1] and rewardConf.RewardItem[1].Type == _G.Enum.GoodsType.GT_GET_PHOTO then
          table.insert(rewardList, {
            finishedStarNum = finishedStarNum,
            bIsTakingPhoto = true,
            is_finish = false,
            star_required_num = v.star_required_num,
            state = v.state,
            difficultyRequire = v.magic_lv_required
          })
        else
          table.insert(rewardList, {
            finishedStarNum = finishedStarNum,
            reward_id = v.reward_id,
            star_required_num = v.star_required_num,
            bIsTakingPhoto = false,
            is_finish = v.state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE,
            state = v.state,
            difficultyRequire = v.magic_lv_required
          })
        end
      else
        table.insert(rewardList, {
          finishedStarNum = finishedStarNum,
          bIsTakingPhoto = true,
          is_finish = false,
          star_required_num = v.star_required_num,
          state = v.state,
          difficultyRequire = v.magic_lv_required
        })
      end
    end
  end
  return rewardList
end

function WeeklyChallengeBattleModule:OnCmdOpenRewardClaimPopupPanel(rewardList, bIsInActivity)
  local bIsOpening, _ = self:HasPanel("RewardClaim")
  if bIsOpening then
    return
  end
  self:OpenPanel("RewardClaim", rewardList, bIsInActivity)
end

function WeeklyChallengeBattleModule:OnCmdGoTakePhoto()
  self:ClosePanel("RewardClaim")
  local bIsOpening, _ = self:HasPanel("StarlightShowDown")
  if bIsOpening then
    self:ClosePanel("StarlightShowDown")
  end
  bIsOpening, _ = self:HasPanel("TeamEdit")
  if bIsOpening then
    self:ClosePanel("TeamEdit")
  end
  bIsOpening, _ = self:HasPanel("PetDetail")
  if bIsOpening then
    self:ClosePanel("PetDetail")
  end
  local photoPanel = self:GetPanel("StarlightPhoto")
  if photoPanel then
    photoPanel:SwitchToTeamPanelFromMain()
  end
end

function WeeklyChallengeBattleModule:SendReceiveRewardReq(activityId, starRequireNum, rewardList, activityType)
  self.receiveRewardActivityId = activityId
  self.receiveRewardStarRequireNum = starRequireNum
  self.receiveRewardRewardList = rewardList
  self.receiveRewardActivityType = activityType
  local req = _G.ProtoMessage:newZoneChallengeStarRewardReq()
  req.activity_id = activityId
  req.star_num = starRequireNum
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHALLENGE_STAR_REWARD_REQ, req, self, self.ReceiveRewardRsp, true, false)
end

function WeeklyChallengeBattleModule:ReceiveRewardRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error(string.format("\232\142\183\229\143\150\229\165\150\229\138\177\232\175\183\230\177\130\229\164\177\232\180\165\239\188\140\232\191\148\229\155\158\233\148\153\232\175\175\231\160\129 %s", rsp.ret_info.ret_code))
    return
  end
  self:DispatchEvent(WeeklyChallengeBattleModuleEvent.ReceiveRewardSuccess, self.receiveRewardActivityId, self.receiveRewardStarRequireNum, self.receiveRewardActivityType)
end

function WeeklyChallengeBattleModule:OnCmdOpenFirstDebutPetChoosePanel()
  local bIsOpening, _ = self:HasPanel("FirstDebutPetChoose")
  if bIsOpening then
    return
  end
  self:OpenPanel("FirstDebutPetChoose", self.data.CurrentTeamPetList)
end

function WeeklyChallengeBattleModule:OnCmdChangeFirstDebutPet(firstDebutPet)
  self.data.FirstDebutPet = firstDebutPet
end

function WeeklyChallengeBattleModule:OnCmdResetPetStateReq(activityId, challengeId)
  local req = ProtoMessage:newZoneWeeklyChallengeAttrBalanceReq()
  req.activity_id = activityId
  req.challenge_id = challengeId
  Log.Info("\229\143\145\233\128\129\229\174\160\231\137\169\231\138\182\230\128\129\233\135\141\231\189\174\232\175\183\230\177\130")
  self.bIsResetDataDirty = true
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_WEEKLY_CHALLENGE_ATTR_BALANCE_REQ, req, self, self.ResetPetStateRsq, false, false)
end

function WeeklyChallengeBattleModule:ResetPetStateRsq(rsp)
  self.bIsResetDataDirty = false
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("\229\174\160\231\137\169\231\138\182\230\128\129\233\135\141\231\189\174\229\164\177\232\180\165")
    return
  end
  Log.Info(string.format("\229\174\160\231\137\169\233\135\141\231\189\174\231\138\182\230\128\129\239\188\154 level %s, grow %s, \230\152\175\229\144\166\233\156\128\232\166\129\229\185\179\232\161\161 %s", rsp.balance_level, rsp.balance_grow, rsp.is_need_balance))
  self.data.PetResetLevel = rsp.balance_level
  self.data.PetResetGrow = rsp.balance_grow
  self.data.PetResetWorkhard = rsp.balance_effort
  self.data.bIsNeedBalance = rsp.is_need_balance
  self.data.opponentLevels = rsp.monster_level
  self.data.opponentConfIds = rsp.monster_conf_id
  if self.data.opponentLevels and self.data.opponentConfIds then
    local levels = self.data.opponentLevels
    local confIds = self.data.opponentConfIds
    local count = math.min(#levels, #confIds)
    Log.Info("\232\142\183\229\143\150\229\175\185\230\137\139\228\191\161\230\129\175\239\188\154")
    for i = 1, count do
      Log.Info(string.format("\231\173\137\231\186\167: %d, \233\133\141\231\189\174ID: %d", levels[i], confIds[i]))
    end
  else
    Log.Error("\229\175\185\230\137\139\231\173\137\231\186\167\230\136\150\233\133\141\231\189\174ID\230\149\176\230\141\174\228\184\141\229\173\152\229\156\168\227\128\130")
  end
  self:DispatchEvent(WeeklyChallengeBattleModuleEvent.OnResetDataChangedEvent, rsp.pet_data, rsp.balance_level, rsp.balance_grow, rsp.balance_effort)
end

function WeeklyChallengeBattleModule:GetRivalPetInitList()
  if not self.data.opponentLevels or not self.data.opponentConfIds then
    Log.Error("WeeklyChallengeBattleModule:GetRivalPetInitList \232\142\183\229\143\150\229\175\185\230\137\139\230\149\176\230\141\174\229\164\177\232\180\165")
    return
  end
  if #self.data.opponentLevels ~= #self.data.opponentConfIds then
    Log.Error("\229\175\185\230\137\139\230\149\176\233\135\143\229\146\140\229\175\185\230\137\139\231\154\132\231\173\137\231\186\167\230\149\176\233\135\143\233\149\191\229\186\166\228\184\141\229\175\185\231\173\137")
    return
  end
  local result = {}
  local size = #self.data.opponentLevels
  for i = 1, size do
    local monsterConf = _G.DataConfigManager:GetMonsterConf(self.data.opponentConfIds[i])
    if not monsterConf then
      Log.Error(string.format("\229\140\133\229\144\171\228\184\141\229\173\152\229\156\168\231\154\132monster id\239\188\140\232\175\183\230\163\128\230\159\165\233\133\141\231\189\174 %s", self.data.opponentConfIds[i]))
      return {}
    end
    table.insert(result, {
      petBaseId = monsterConf.base_id,
      level = self.data.opponentLevels[i]
    })
  end
  return result
end

function WeeklyChallengeBattleModule:OnCmdIsNeedBalance()
  return self.data.bIsNeedBalance
end

function WeeklyChallengeBattleModule:OnCmdGetBalanceInfo()
  return self.data.PetResetInfo, self.data.PetResetLevel, self.data.PetResetGrow, self.data.PetResetWorkhard
end

function WeeklyChallengeBattleModule:OnCmdRefetchTeamList()
  self.data:RefetchTeamList()
end

function WeeklyChallengeBattleModule:OnCmdOpenResetNotification(bIsWeeklyMax, resetGrow, resetLevel, resetWorkHard)
  local bIsOpening, _ = self:HasPanel("ResetNotification")
  if bIsOpening then
    return
  end
  self:OpenPanel("ResetNotification", bIsWeeklyMax, resetGrow, resetLevel, resetWorkHard)
end

function WeeklyChallengeBattleModule:OnCmdCloseFirstDebutPetChoosePanel()
  local bIsOpening, _ = self:HasPanel("StarlightShowDown")
  if bIsOpening then
    local panel = self:GetPanel("StarlightShowDown")
    if panel then
      panel:OnFirstDebutPetChoosePanelClosed()
    end
  end
end

function WeeklyChallengeBattleModule:ClosePhotoPanel()
  local bIsOpening, _ = self:HasPanel("StarlightPhoto")
  if bIsOpening then
    local panel = self:GetPanel("StarlightPhoto")
    if panel then
      panel:DoClose()
    end
  end
end

function WeeklyChallengeBattleModule:OnPreTeleportNotify()
  local bIsPhotoOpening, _ = self:HasPanel("StarlightPhoto")
  if bIsPhotoOpening then
    local panel = self:GetPanel("StarlightPhoto")
    if panel and panel.npcAction and panel.npcAction.Finish then
      panel.npcAction:Finish()
      panel.npcAction = nil
    end
  end
  local panelNames = {
    "StarlightPhoto",
    "StarlightShowDown"
  }
  for _, panelName in ipairs(panelNames) do
    local bIsOpening, _ = self:HasPanel(panelName)
    if bIsOpening then
      self:ClosePanel(panelName)
    end
  end
end

function WeeklyChallengeBattleModule:OnCmdAddDontDisablePanelToList(panelName)
  self.DontDisablePanelList[panelName] = panelName
end

function WeeklyChallengeBattleModule:DisablePanelByLayer(layer)
  for i = 1, #self.moduleLivingPanelLst do
    local panelName = self.moduleLivingPanelLst[i]
    local panelData = self:GetPanelData(panelName)
    if panelData.panelLayer == layer and self:IsPanelEnabled(panelName) then
      if self.modulePanelPrevStatueDict[panelName] ~= nil then
        self:Log("\232\175\183\229\139\191\229\164\154\230\172\161\232\176\131\231\148\168DisablePanelByLayer\239\188\140\232\176\131\231\148\168DisablePanelByLayer\229\144\142\233\156\128\232\166\129\232\176\131\231\148\168RevertPanelEnableStateByLayer\229\164\141\229\142\159UI\231\138\182\230\128\129", layer)
        return
      end
      if not self.DontDisablePanelList[panelName] then
        self.modulePanelPrevStatueDict[panelName] = false
        self:DisablePanel(panelName)
      else
        Log.Debug("\232\175\165\233\157\162\230\157\191\232\162\171\230\148\190\229\133\165\232\191\155\230\136\152\230\150\151\233\152\178\231\187\159\228\184\128\229\133\179\233\151\173\231\154\132\233\157\162\230\157\191\229\136\151\232\161\168\239\188\140\230\173\164\229\164\132\228\184\141Disable\232\175\165\233\157\162\230\157\191\239\188\154" .. panelName)
      end
    end
  end
end

function WeeklyChallengeBattleModule:OnLoadPhotoPanelRes()
  local ResListData = _G.NRCPanelResLoadData()
  ResListData.PreLoadResList = {}
  table.insert(ResListData.PreLoadResList, UEPath.ABP_STARLIGHT_PLAYER_MALE)
  table.insert(ResListData.PreLoadResList, UEPath.ANIM_CONFIG_MALE)
  table.insert(ResListData.PreLoadResList, UEPath.ABP_STARLIGHT_PLAYER_FEMALE)
  table.insert(ResListData.PreLoadResList, UEPath.ANIM_CONFIG_FEMALE)
  return ResListData
end

function WeeklyChallengeBattleModule:GetJsonNameFromID(photo_template_id)
  local photoConf = DataConfigManager:GetWeeklyPhotoConf(photo_template_id)
  if not photoConf then
    Log.Error(string.format("UMG_WeeklyChallengeBattle_StarlightReview_C:GetJsonPathFromID \232\142\183\229\143\150photoConf\229\164\177\232\180\165"))
    return ""
  end
  local jsonPath = photoConf.res_name
  return jsonPath
end

function WeeklyChallengeBattleModule:GetMaterialPathFromPhotoID(photo_template_id)
  local JsonName = self:GetJsonNameFromID(photo_template_id)
  local SaveJsonInfoList = JsonUtils.LoadSavedFromStarLight(JsonName, {})
  local FilePrefix = "/Game/ArtRes/Asset/Environment/Interator/Curtain/TEX/"
  if 0 == #SaveJsonInfoList then
    Log.Error("\230\178\161\230\156\137" .. JsonName .. "\229\175\185\229\186\148\231\154\132json\230\150\135\228\187\182\239\188\140\228\189\191\231\148\168\233\187\152\232\174\164\230\149\176\230\141\174")
    return "/Game/ArtRes/Asset/Environment/Interator/Curtain/TEX/MI_Curtain_001_01_Skeletal.MI_Curtain_001_01_Skeletal"
  end
  local GlobalInfo = SaveJsonInfoList[1]
  local FileName = GlobalInfo[2]
  return FilePrefix .. FileName .. "." .. FileName
end

function WeeklyChallengeBattleModule:GetMaterialFileNameFromPhotoID(photo_template_id)
  local JsonName = self:GetJsonNameFromID(photo_template_id)
  local SaveJsonInfoList = JsonUtils.LoadSavedFromStarLight(JsonName, {})
  if 0 == #SaveJsonInfoList then
    return nil
  end
  local GlobalInfo = SaveJsonInfoList[1]
  local FileName = GlobalInfo[2]
  return FileName
end

function WeeklyChallengeBattleModule:OnCmdSetPlaySequenceState(state)
  self.IsPlaySequence = state
end

function WeeklyChallengeBattleModule:OnCmdGetPlaySequenceState()
  return self.IsPlaySequence
end

function WeeklyChallengeBattleModule:OnCmdGetWeeklyChallengeConf()
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  local weekly_challenge_data
  if WeeklyChallengeEventActivityObject and WeeklyChallengeEventActivityObject[1] then
    weekly_challenge_data = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
    if weekly_challenge_data then
      self.challengeId = weekly_challenge_data.challenge_info.challenge_id
      local challengeConf = _G.DataConfigManager:GetWeeklyChallengeConf(self.challengeId)
      return challengeConf
    end
  end
  return nil
end

function WeeklyChallengeBattleModule:OnCmdSaveWeeklyChallengeLevelSequencePlayer(levelSequencePlayer, levelSequenceActor)
  self.levelSequencePlayer = levelSequencePlayer
  self.levelSequenceActor = levelSequenceActor
  self.levelSequenceActorRef = UnLua.Ref(self.levelSequenceActor)
end

function WeeklyChallengeBattleModule:OnCmdClearWeeklyChallengeLevelSequencePlayer()
  if self.levelSequencePlayer then
    self.levelSequencePlayer:Stop()
    self.levelSequencePlayer = nil
  end
  if self.levelSequenceActor then
    self.levelSequenceActor:Destroy()
    self.levelSequenceActor = nil
  end
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseBlackBar)
  _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.ModifySceneSpotLight, true)
  if self.levelSequenceActorRef and UE.UObject.IsValid(self.levelSequenceActorRef) then
    UnLua.Unref(self.levelSequenceActorRef)
  end
  self.levelSequenceActorRef = nil
end

function WeeklyChallengeBattleModule:TrySetBgmToTheater()
  if not self.bIsPlayingTheater then
    self:SetBgmToTheater()
  end
end

function WeeklyChallengeBattleModule:SetBgmToTheater()
  _G.NRCAudioManager:BatchSetState("UI_Music;UI_Music;UI_Type;DuiZhan_Theater")
  self.bIsPlayingTheater = true
end

function WeeklyChallengeBattleModule:ClearBgm()
  _G.NRCAudioManager:BatchSetState("UI_Music;None")
  self.bIsPlayingTheater = false
end

function WeeklyChallengeBattleModule:SetCanClearBgm(bCanClearBgm)
  self.bCanClearBgm = bCanClearBgm
end

function WeeklyChallengeBattleModule:TryClearBgm()
  if self.bCanClearBgm then
    self:ClearBgm()
  end
end

function WeeklyChallengeBattleModule:OnCmdModifySceneSpotLight(isShow)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    return
  end
  local SpotLightActor = localPlayer.viewObj.SpotLightActor
  if SpotLightActor then
    SpotLightActor.bNumb = isShow
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  local LightsArray = UE4.UGameplayStatics.GetAllActorsOfClass(World, UE4.AEnvSpotLightActor)
  local Lights = LightsArray and LightsArray:ToTable()
  if Lights and #Lights > 0 then
    for _, light in pairs(Lights) do
      light:SetActorHiddenInGame(not isShow)
    end
  end
  local LightsArray1 = UE4.UGameplayStatics.GetAllActorsOfClass(World, UE4.AEnvPointLightActor)
  local Lights1 = LightsArray1 and LightsArray1:ToTable()
  if Lights1 and #Lights1 > 0 then
    for _, light in pairs(Lights1) do
      light:SetActorHiddenInGame(not isShow)
    end
  end
end

function WeeklyChallengeBattleModule:IsCheerUpRuleSatisfy(petCatchList, mutationDiffTypeList, petTypeList, petData)
  if not (petData and petData.gid) or 0 == petData.gid then
    return false, 0
  end
  if not petData.cheer_point_info then
    return false, 0
  end
  for k, v in ipairs(petData.cheer_point_info) do
    local bFound1 = false
    local bFound2 = false
    local bFound3 = false
    if v.catch_way and #petCatchList > 0 then
      for k1, v1 in ipairs(petCatchList) do
        if v1 == v.catch_way then
          bFound1 = true
        end
      end
    elseif 0 == #petCatchList and (v.catch_way == nil or 0 == v.catch_way) then
      bFound1 = true
    end
    if v.mutation_type and #mutationDiffTypeList > 0 then
      for k1, v1 in ipairs(mutationDiffTypeList) do
        if v1 == v.mutation_type then
          bFound2 = true
        end
      end
    elseif 0 == #mutationDiffTypeList and (nil == v.mutation_type or 0 == v.mutation_type) then
      bFound2 = true
    end
    if v.pet_type and #petTypeList > 0 then
      for k1, v1 in ipairs(petTypeList) do
        if v1 == v.pet_type then
          bFound3 = true
        end
      end
    elseif 0 == #petTypeList and (nil == v.pet_type or 0 == v.pet_type) then
      bFound3 = true
    end
    if bFound1 and bFound2 and bFound3 then
      return true, v.cheer_point
    end
  end
  return false, 0
end

function WeeklyChallengeBattleModule:OpenCheerUpPointTips(petData)
  local bHas = self:HasPanel("CheerUpPointTips")
  if not bHas then
    self:OpenPanel("CheerUpPointTips", petData)
  end
end

local QUERY_ALL_PET_BALANCED_DATA_TIMEOUT = 5

function WeeklyChallengeBattleModule:QueryAllUsablePetBalancedData()
  if self.data.IsQueryingAllPetBalanceData then
    Log.Info("WeeklyChallengeBattleModule:QueryAllUsablePetBalancedData Already querying, skip")
    return
  end
  self.pendingBalancedDataReadyCallbacks = {}
  self.data:ClearAllPetBalancedDataCache()
  local allPetData = _G.DataModelMgr.PlayerDataModel:GetPetData()
  if not allPetData or 0 == #allPetData then
    Log.Info("WeeklyChallengeBattleModule:QueryAllUsablePetBalancedData No pet data found")
    return
  end
  local usablePetGids = {}
  for _, petData in ipairs(allPetData) do
    if self.data:_IsThisWeekCatchPet(petData) then
      table.insert(usablePetGids, petData.gid)
    end
  end
  if 0 == #usablePetGids then
    Log.Info("WeeklyChallengeBattleModule:QueryAllUsablePetBalancedData No usable pets this week")
    return
  end
  self.data.AllUsablePetGids = usablePetGids
  self.data.PendingQueryPetGids = {}
  for _, gid in ipairs(usablePetGids) do
    table.insert(self.data.PendingQueryPetGids, gid)
  end
  self.data.IsQueryingAllPetBalanceData = true
  self:ClearQueryAllPetBalancedDataTimeout()
  self.queryAllPetBalancedDataTimeoutHandle = _G.DelayManager:DelaySeconds(QUERY_ALL_PET_BALANCED_DATA_TIMEOUT, function()
    self:OnQueryAllPetBalancedDataTimeout()
  end, false)
  Log.Info(string.format("WeeklyChallengeBattleModule:QueryAllUsablePetBalancedData Start querying %d pets", #usablePetGids))
  self:TrySendNextBatchQueryBalancedAttr()
end

function WeeklyChallengeBattleModule:RefreshAllUsablePetBalancedData()
  Log.Info("WeeklyChallengeBattleModule:RefreshAllUsablePetBalancedData Force refresh all pet balanced data")
  self:ClearQueryAllPetBalancedDataTimeout()
  self.data.IsQueryingAllPetBalanceData = false
  self.data.PendingQueryPetGids = {}
  self:QueryAllUsablePetBalancedData()
end

function WeeklyChallengeBattleModule:RefreshSinglePetBalancedData(petGid, callback)
  if not petGid or 0 == petGid then
    Log.Warning("WeeklyChallengeBattleModule:RefreshSinglePetBalancedData Invalid petGid")
    if callback then
      callback(false)
    end
    return
  end
  if not self.data.AllPetBalancedDataMap[petGid] then
    Log.Info(string.format("WeeklyChallengeBattleModule:RefreshSinglePetBalancedData Pet %d not in balanced data map, skipping", petGid))
    if callback then
      callback(false)
    end
    return
  end
  Log.Info(string.format("WeeklyChallengeBattleModule:RefreshSinglePetBalancedData Refreshing pet gid: %d", petGid))
  local req = _G.ProtoMessage:newZoneQueryPetBalancedAttrReq()
  req.gid = {petGid}
  req.is_weekly_challenge = true
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_PET_BALANCED_ATTR_REQ, req, self, function(self, rsp)
    self:OnSinglePetBalancedAttrRsp(rsp, petGid, callback)
  end, false, false)
end

function WeeklyChallengeBattleModule:OnSinglePetBalancedAttrRsp(rsp, petGid, callback)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error(string.format("WeeklyChallengeBattleModule:OnSinglePetBalancedAttrRsp Error code: %d for pet gid: %d", rsp.ret_info.ret_code, petGid))
    if callback then
      callback(false)
    end
    return
  end
  local equipSkillsMap = self:GetEquipSkillsMapFromActivityData()
  if rsp.pet_data then
    for _, petData in ipairs(rsp.pet_data) do
      if petData.gid and 0 ~= petData.gid then
        self:ApplyEquipSkillsToPetData(petData, equipSkillsMap)
        self.data.AllPetBalancedDataMap[petData.gid] = petData
        Log.Info(string.format("WeeklyChallengeBattleModule:OnSinglePetBalancedAttrRsp Updated pet gid: %d", petData.gid))
      end
    end
  end
  self:DispatchEvent(WeeklyChallengeBattleModuleEvent.OnSinglePetBalancedDataReady, petGid)
  if callback then
    callback(true)
  end
end

function WeeklyChallengeBattleModule:RefreshMultiplePetsBalancedData(petGidList, callback)
  if not petGidList or 0 == #petGidList then
    Log.Warning("WeeklyChallengeBattleModule:RefreshMultiplePetsBalancedData Invalid or empty petGidList")
    if callback then
      callback(false)
    end
    return
  end
  local validGids = {}
  for _, petGid in ipairs(petGidList) do
    if petGid and 0 ~= petGid and self.data.AllPetBalancedDataMap[petGid] then
      table.insert(validGids, petGid)
    end
  end
  if 0 == #validGids then
    Log.Info("WeeklyChallengeBattleModule:RefreshMultiplePetsBalancedData No valid pets to refresh")
    if callback then
      callback(false)
    end
    return
  end
  Log.Info(string.format("WeeklyChallengeBattleModule:RefreshMultiplePetsBalancedData Refreshing %d pets", #validGids))
  local req = _G.ProtoMessage:newZoneQueryPetBalancedAttrReq()
  req.gid = validGids
  req.is_weekly_challenge = true
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_PET_BALANCED_ATTR_REQ, req, self, function(self, rsp)
    self:OnMultiplePetsBalancedAttrRsp(rsp, validGids, callback)
  end, false, false)
end

function WeeklyChallengeBattleModule:OnMultiplePetsBalancedAttrRsp(rsp, petGidList, callback)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error(string.format("WeeklyChallengeBattleModule:OnMultiplePetsBalancedAttrRsp Error code: %d", rsp.ret_info.ret_code))
    if callback then
      callback(false)
    end
    return
  end
  local equipSkillsMap = self:GetEquipSkillsMapFromActivityData()
  local updatedGids = {}
  if rsp.pet_data then
    for _, petData in ipairs(rsp.pet_data) do
      if petData.gid and 0 ~= petData.gid then
        self:ApplyEquipSkillsToPetData(petData, equipSkillsMap)
        self.data.AllPetBalancedDataMap[petData.gid] = petData
        table.insert(updatedGids, petData.gid)
        Log.Info(string.format("WeeklyChallengeBattleModule:OnMultiplePetsBalancedAttrRsp Updated pet gid: %d", petData.gid))
      end
    end
  end
  self:DispatchEvent(WeeklyChallengeBattleModuleEvent.OnMultiplePetsBalancedDataReady, updatedGids)
  if callback then
    callback(true)
  end
end

function WeeklyChallengeBattleModule:ClearQueryAllPetBalancedDataTimeout()
  if self.queryAllPetBalancedDataTimeoutHandle then
    _G.DelayManager:CancelDelayById(self.queryAllPetBalancedDataTimeoutHandle)
    self.queryAllPetBalancedDataTimeoutHandle = nil
  end
end

function WeeklyChallengeBattleModule:OnQueryAllPetBalancedDataTimeout()
  Log.Warning("WeeklyChallengeBattleModule:OnQueryAllPetBalancedDataTimeout Query timed out, resetting state")
  self.queryAllPetBalancedDataTimeoutHandle = nil
  self.data.IsQueryingAllPetBalanceData = false
  self.data.PendingQueryPetGids = {}
  self:ExecutePendingBalancedDataReadyCallbacks()
  self:DispatchEvent(WeeklyChallengeBattleModuleEvent.OnAllPetBalancedDataReady)
end

function WeeklyChallengeBattleModule:TrySendNextBatchQueryBalancedAttr()
  if 0 == #self.data.PendingQueryPetGids then
    self.data.IsQueryingAllPetBalanceData = false
    self:ClearQueryAllPetBalancedDataTimeout()
    Log.Info("WeeklyChallengeBattleModule:TrySendNextBatchQueryBalancedAttr All queries completed")
    self:ExecutePendingBalancedDataReadyCallbacks()
    self:DispatchEvent(WeeklyChallengeBattleModuleEvent.OnAllPetBalancedDataReady)
    return
  end
  local batchGids = {}
  local batchSize = math.min(10, #self.data.PendingQueryPetGids)
  for i = 1, batchSize do
    local gid = table.remove(self.data.PendingQueryPetGids, 1)
    table.insert(batchGids, gid)
  end
  local req = _G.ProtoMessage:newZoneQueryPetBalancedAttrReq()
  req.gid = batchGids
  req.is_weekly_challenge = true
  Log.Info(string.format("WeeklyChallengeBattleModule:TrySendNextBatchQueryBalancedAttr Sending batch with %d pets, %d remaining", #batchGids, #self.data.PendingQueryPetGids))
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_PET_BALANCED_ATTR_REQ, req, self, self.OnQueryPetBalancedAttrRsp, false, false)
end

function WeeklyChallengeBattleModule:OnQueryPetBalancedAttrRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error(string.format("WeeklyChallengeBattleModule:OnQueryPetBalancedAttrRsp Error code: %d", rsp.ret_info.ret_code))
    self:TrySendNextBatchQueryBalancedAttr()
    return
  end
  local equipSkillsMap = self:GetEquipSkillsMapFromActivityData()
  if rsp.pet_data then
    for _, petData in ipairs(rsp.pet_data) do
      if petData.gid and 0 ~= petData.gid then
        self:ApplyEquipSkillsToPetData(petData, equipSkillsMap)
        self.data.AllPetBalancedDataMap[petData.gid] = petData
        Log.Info(string.format("WeeklyChallengeBattleModule:OnQueryPetBalancedAttrRsp Cached pet gid: %d", petData.gid))
      end
    end
  end
  self:TrySendNextBatchQueryBalancedAttr()
end

function WeeklyChallengeBattleModule:GetEquipSkillsMapFromActivityData()
  local equipSkillsMap = {}
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if not WeeklyChallengeEventActivityObject or not WeeklyChallengeEventActivityObject[1] then
    return equipSkillsMap
  end
  local weekly_challenge_data = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
  if not weekly_challenge_data or not weekly_challenge_data.equip_skills then
    return equipSkillsMap
  end
  for _, equipSkill in ipairs(weekly_challenge_data.equip_skills) do
    if equipSkill.pet_gid and 0 ~= equipSkill.pet_gid then
      equipSkillsMap[equipSkill.pet_gid] = equipSkill.equip_infos
    end
  end
  return equipSkillsMap
end

function WeeklyChallengeBattleModule:ApplyEquipSkillsToPetData(petData, equipSkillsMap)
  if not petData or not petData.gid then
    return
  end
  local savedEquipInfos = equipSkillsMap[petData.gid]
  if not savedEquipInfos or 0 == #savedEquipInfos then
    return
  end
  if not petData.skill or not petData.skill.skill_data then
    return
  end
  local savedEquipMap = {}
  for _, equipInfo in ipairs(savedEquipInfos) do
    if equipInfo.id and equipInfo.pos then
      savedEquipMap[equipInfo.id] = equipInfo.pos
    end
  end
  for _, skillData in ipairs(petData.skill.skill_data) do
    local savedPos = savedEquipMap[skillData.id]
    if savedPos then
      skillData.is_equipped = true
      skillData.pos = savedPos
    else
      skillData.is_equipped = false
      skillData.pos = 0
    end
  end
  Log.Info(string.format("WeeklyChallengeBattleModule:ApplyEquipSkillsToPetData Applied saved equip_skills to pet gid: %d", petData.gid))
end

function WeeklyChallengeBattleModule:OnCmdGetAllUsablePetGids()
  return self.data:GetAllUsablePetGids()
end

function WeeklyChallengeBattleModule:OnCmdGetPetBalancedDataByGid(gid)
  return self.data:GetPetBalancedDataByGid(gid)
end

function WeeklyChallengeBattleModule:OnCmdIsAllPetBalancedDataReady()
  return self.data:IsAllPetBalancedDataReady()
end

function WeeklyChallengeBattleModule:OnCmdAddBalancedDataReadyCallback(callback)
  if not callback then
    return
  end
  if self.data:IsAllPetBalancedDataReady() then
    Log.Info("WeeklyChallengeBattleModule:OnCmdAddBalancedDataReadyCallback Data already ready, executing callback immediately")
    callback()
    return
  end
  if not self.pendingBalancedDataReadyCallbacks then
    self.pendingBalancedDataReadyCallbacks = {}
  end
  table.insert(self.pendingBalancedDataReadyCallbacks, callback)
  Log.Info(string.format("WeeklyChallengeBattleModule:OnCmdAddBalancedDataReadyCallback Added callback, total pending: %d", #self.pendingBalancedDataReadyCallbacks))
end

function WeeklyChallengeBattleModule:ExecutePendingBalancedDataReadyCallbacks()
  if not self.pendingBalancedDataReadyCallbacks or 0 == #self.pendingBalancedDataReadyCallbacks then
    return
  end
  Log.Info(string.format("WeeklyChallengeBattleModule:ExecutePendingBalancedDataReadyCallbacks Executing %d pending callbacks", #self.pendingBalancedDataReadyCallbacks))
  local callbacks = self.pendingBalancedDataReadyCallbacks
  self.pendingBalancedDataReadyCallbacks = {}
  for _, callback in ipairs(callbacks) do
    local success, err = pcall(callback)
    if not success then
      Log.Error(string.format("WeeklyChallengeBattleModule:ExecutePendingBalancedDataReadyCallbacks Callback error: %s", tostring(err)))
    end
  end
end

function WeeklyChallengeBattleModule:GetResetSkillByGid(petGid)
  local balancedPetData = self:OnCmdGetPetBalancedDataByGid(petGid)
  if balancedPetData and balancedPetData.skill and balancedPetData.skill.skill_data then
    local posToIdDic = {}
    for _, skillData in ipairs(balancedPetData.skill.skill_data) do
      if skillData.is_equipped and skillData.pos and skillData.pos > 0 and skillData.pos < 5 then
        posToIdDic[skillData.pos] = skillData.id
      end
    end
    return posToIdDic
  end
  return {}
end

return WeeklyChallengeBattleModule
