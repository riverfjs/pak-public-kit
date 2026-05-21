local LevelSelectionEnum = require("NewRoco.Modules.System.LevelSelection.LevelSelectionEnum")
local LevelSelectionModuleEvent = require("NewRoco.Modules.System.LevelSelection.LevelSelectionModuleEvent")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local LevelSelectionModule = NRCModuleBase:Extend("LevelSelectionModule")

function LevelSelectionModule:OnConstruct()
  _G.LevelSelectionModuleCmd = reload("NewRoco.Modules.System.LevelSelection.LevelSelectionModuleCmd")
  self.data = self:SetData("LevelSelectionModuleData", "NewRoco.Modules.System.LevelSelection.LevelSelectionModuleData")
  self:RegPanel("Leve_BattleSilhouette", "UMG_Leve_BattleSilhouette", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, false, nil, nil, nil)
  self:RegPanel("Leve_Select", "UMG_Leve_Select", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, nil)
  self:RegPanel("ClearanceReward", "UMG_Leve_ClearanceReward", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Leve_BattleArray", "UMG_Leve_battleArray", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Leve_BattleTeam", "UMG_Level_Team", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Leve_Rule", "UMG_Level_MagicGain", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("LevelFirstPublish", "UMG_Level_FirstPublish", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Level_LeaderTrait_Tips", "UMG_LeaderTrait_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("LoadingCurtain", "UMG_Curtain", _G.Enum.UILayerType.UI_LAYER_GLOBAL_BLACK)
  _G.NRCModuleManager:GetModule("PetUIModule"):RegisterEvent(self, PetUIModuleEvent.EquipmentOrRemoveBloodEvent, self.UpdateBloodLineMagic)
  _G.NRCEventCenter:RegisterEvent("LevelSelectionModule", self, PetUIModuleEvent.PetTeamEquipPetMagicRsp, self.UpdateBloodLineMagic)
  _G.NRCEventCenter:RegisterEvent("LevelSelectionModule", self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnEnterSceneFinishNtyAckEnd)
  _G.NRCEventCenter:RegisterEvent("LevelSelectionModule", self, MainUIModuleEvent.MAINUICLOSE, self.OnMainUIClose)
  _G.NRCEventCenter:RegisterEvent("LevelSelectionModule", self, MainUIModuleEvent.MAINUIOPEN, self.OnMainUIOpen)
  _G.NRCEventCenter:RegisterEvent("LevelSelectionModule", self, SceneEvent.LoadMapStart, self.OnSceneLeave)
  _G.NRCEventCenter:RegisterEvent("LevelSelectionModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.NRCEventCenter:RegisterEvent("LevelSelectionModule", self, SceneEvent.OnTeleportNotify, self.OnTeleportNotify)
  self.IsCurrentTeam = false
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_BOSS_CHALLENGE_FAIL_NOTIFY, self.OnSceneBossChallengeFailNotify)
end

function LevelSelectionModule:OnActive()
end

function LevelSelectionModule:OnRelogin()
end

function LevelSelectionModule:OnDeactive()
end

function LevelSelectionModule:OnDestruct()
end

function LevelSelectionModule:OnSceneBossChallengeFailNotify()
  _G.DelayManager:DelaySeconds(5, function()
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenNpcBattleFailure, nil, true)
  end)
end

function LevelSelectionModule:OnTeleportNotify()
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseNpcBattleFailure)
end

function LevelSelectionModule:OnSceneLeave()
  if self.IsTeleport then
    if self.IsTeleport == 700000 then
      self:OnCmdOpenLeveBattleSilhouette()
    elseif self.IsTeleport == 700001 then
      self:OnCmdOpenLeveSelect()
    elseif self.IsTeleport == 700002 then
      self:OnCmdOpenWeeklyChallengeBattle(self.TeleportArgs[1])
    else
      self:OnCmdOpenLeveBattleSilhouette()
    end
    self.IsTeleport = nil
  end
end

function LevelSelectionModule:OnCmdTeleportChallenge(_TeleportId, ...)
  self.IsTeleport = _TeleportId
  self.TeleportArgs = {
    ...
  }
end

function LevelSelectionModule:OnCmdOpenLeveBattleSilhouette(npcAction, index)
  self:OpenPanel("Leve_BattleSilhouette", npcAction, index)
end

function LevelSelectionModule:OnCmdCloseLeveBattleSilhouette()
  self:ClosePanel("Leve_BattleSilhouette")
end

function LevelSelectionModule:OnCmdHasLoadingCurtain()
  return self:HasPanel("LoadingCurtain")
end

function LevelSelectionModule:OnCmdOpenLoadingCurtain(...)
  local args = {
    ...
  }
  local Caller = args[1]
  local CallBack = args[2]
  if self:HasPanel("LoadingCurtain") then
    if Caller and CallBack then
      CallBack(Caller)
    elseif CallBack then
      CallBack()
    end
  else
    self:OpenPanel("LoadingCurtain", ...)
  end
end

function LevelSelectionModule:OnCmdCloseLoadingCurtain(npcAction)
  if self:HasPanel("LoadingCurtain") then
    local Panel = self:GetPanel("LoadingCurtain")
    if Panel then
      Panel:TryClose()
    end
  end
end

function LevelSelectionModule:OnCmdOpenLeveSelect(npcAction)
  self:OpenPanel("Leve_Select", npcAction)
end

function LevelSelectionModule:OnCmdCloseLeveSelect(npcAction)
  self:ClosePanel("Leve_Select", npcAction)
end

function LevelSelectionModule:OnCmdOpenWeeklyChallengeBattle(bIsDirectPhoto)
  local flag = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_DIA_XINGGUANG_1)
  local bCanOpen = true
  local optionConf = _G.DataConfigManager:GetNpcOptionConf(770000003)
  if optionConf and _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    if optionConf.online_process == _G.ProtoEnum.OnlineVisitProcess.OVP_BOTH_FORBIDED then
      bCanOpen = false
    elseif optionConf.online_process == _G.ProtoEnum.OnlineVisitProcess.OVP_ONLY_OWNER and not _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
      bCanOpen = false
    elseif optionConf.online_process == _G.ProtoEnum.OnlineVisitProcess.OVP_ONLY_GUEST and _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
      bCanOpen = false
    end
  end
  if flag and bCanOpen then
    if bIsDirectPhoto then
      _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenStarlightPhoto, nil, 5)
    else
      _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenStarlightPhoto, nil, 0)
    end
  end
end

function LevelSelectionModule:OnCmdOpenLeaderTraitTips(ruleId, petbaseId, titleStr)
  self:OpenPanel("Level_LeaderTrait_Tips", ruleId, petbaseId, titleStr)
end

function LevelSelectionModule:OnCmdSelectCameraShotItem(_ChallengeLevelData)
  self.data:SetChallengeLevelData(_ChallengeLevelData)
  self:DispatchEvent(LevelSelectionModuleEvent.SelectCameraShotItemEvent, _ChallengeLevelData)
end

function LevelSelectionModule:OnCmdChallengeBgLoadSucceed()
  if self:HasPanel("Leve_BattleSilhouette") then
    local Panel = self:GetPanel("Leve_BattleSilhouette")
    if Panel then
      Panel:ChildPanelLoadSucceed()
    end
  end
end

function LevelSelectionModule:OnCmdOpenLeveClearanceReward(ActivityType)
  self:OpenPanel("ClearanceReward", ActivityType)
end

function LevelSelectionModule:OnCmdSelectTab(TabData)
  self:DispatchEvent(LevelSelectionModuleEvent.SelectTabEvent, TabData)
end

function LevelSelectionModule:OnCmdReceiveAward(star_required_num, activity_id, ActivityType, RewardList)
  self.star_required_num = star_required_num
  self.activity_id = activity_id
  self.ActivityType = ActivityType
  self.RewardList = RewardList
  local Req = _G.ProtoMessage:newZoneChallengeStarRewardReq()
  Req.star_num = star_required_num
  Req.activity_id = activity_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHALLENGE_STAR_REWARD_REQ, Req, self, self.GetZoneChallengeStarRewardRsp, true, false)
end

function LevelSelectionModule:GetZoneChallengeStarRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:DispatchEvent(LevelSelectionModuleEvent.ReceiveAwardSucceed, self.star_required_num, self.ActivityType)
    local itemInfos = {}
    local rewards = self.RewardList
    for _, v in ipairs(rewards) do
      local itemId = v.itemId
      local itemText = v.itemNum
      table.insert(itemInfos, {
        itemId = itemId,
        itemText = itemText,
        id = itemId,
        num = v.itemNum,
        type = v.itemType
      })
    end
    if #itemInfos > 0 then
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, itemInfos)
    end
  end
end

function LevelSelectionModule:OnCmdZoneGetNpcChallengeImageReq(activityId, uid)
  local req = _G.ProtoMessage:newZoneGetNpcChallengeImageReq()
  req.activity_id = activityId
  self.ImageUid = uid
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_NPC_CHALLENGE_IMAGE_REQ, req, self, self.OnZoneGetNpcChallengeImageRsp, false, false)
end

function LevelSelectionModule:OnZoneGetNpcChallengeImageRsp(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.npc_challenge_image_info then
    local imageInfos = rsp.npc_challenge_image_info
    for i = 1, #imageInfos do
      local info = imageInfos[i]
      self.data:SetCacheSalonDataDic(info)
    end
  end
  if self.ImageUid then
    self:DispatchEvent(LevelSelectionModuleEvent.UpdateChallengeImage, self.data.cacheSalonDataDic[self.ImageUid])
    self.ImageUid = nil
  end
end

function LevelSelectionModule:OnCmdSelectBossLevel(ChallengeLevel)
  self:DispatchEvent(LevelSelectionModuleEvent.SelectBossLevelEvent, ChallengeLevel)
end

function LevelSelectionModule:OnCmdOpenBattleSilhouettePanel(battleId)
  self.data:CreateDefaultTeamDatas()
  if self:HasPanel("Leve_BattleArray") then
    local panel = self:GetPanel("Leve_BattleArray")
    panel:OnShowView()
  else
    local ResListData = _G.NRCPanelResLoadData()
    ResListData.PreLoadResList = {}
    local g6 = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/SceneEffect/G6_JianYingJuChang_Loop.G6_JianYingJuChang_Loop_C'"
    if battleId then
      local avatar_param = _G.DataConfigManager:GetNpcChallengeConf(battleId).avatar_param
      local avtatrType = _G.DataConfigManager:GetNpcChallengeConf(battleId).avatar
      if avtatrType == _G.Enum.OpponentType.OT_NPC then
        local moduleId = _G.DataConfigManager:GetNpcConf(avatar_param).model_conf
        local modelPath = _G.DataConfigManager:GetModelConf(moduleId).path
        table.insert(ResListData.PreLoadResList, modelPath)
      else
        table.insert(ResListData.PreLoadResList, UEPath.ANIM_CONFIG_MALE)
        table.insert(ResListData.PreLoadResList, UEPath.ANIM_CONFIG_FEMALE)
        table.insert(ResListData.PreLoadResList, UEPath.DEFAULT_AVATAR_SUIT_MALE)
        table.insert(ResListData.PreLoadResList, UEPath.DEFAULT_AVATAR_SUIT_FEMALE)
        table.insert(ResListData.PreLoadResList, UEPath.ABP_CARD_PLAYER_MALE)
        table.insert(ResListData.PreLoadResList, UEPath.ABP_CARD_PLAYER_FEMALE)
      end
      table.insert(ResListData.PreLoadResList, g6)
    end
    self:OpenPanel("Leve_BattleArray", LevelSelectionEnum.BattlePanel.Silhouette, battleId, ResListData)
  end
end

function LevelSelectionModule:OnCmdOpenBattleBossPanel(battleId)
  self.data:CreateDefaultTeamDatas()
  self:OpenPanel("Leve_BattleArray", LevelSelectionEnum.BattlePanel.Boss, battleId)
end

function LevelSelectionModule:OnCmdCloseBattleSilhouettePanel()
  self:ClosePanel("Leve_BattleArray")
end

function LevelSelectionModule:OnCmdOpenBattleTeamPanel(arg)
  if not self:HasPanel("Leve_BattleTeam") then
    self:OpenPanel("Leve_BattleTeam", arg)
    local ArrayPanel = self:GetPanel("Leve_BattleArray")
    ArrayPanel:OnEnableTeamButton(false)
  end
end

function LevelSelectionModule:OnCmdCloseBattleArrayPanel()
  if self:HasPanel("Leve_BattleTeam") then
    local panel = self:GetPanel("Leve_BattleTeam")
    panel:OnClosePanel()
    if self:HasPanel("Leve_BattleArray") then
      local ArrayPanel = self:GetPanel("Leve_BattleArray")
      ArrayPanel:OnCloseBattleTeamView()
      ArrayPanel:OnEnableTeamButton(true)
    end
  elseif self:HasPanel("Leve_BattleArray") then
    local panel = self:GetPanel("Leve_BattleArray")
    panel:OnClosePanel()
  end
  self:ShowOrHideBattleSilhouette(true)
end

function LevelSelectionModule:ShowOrHideBattleSilhouette(_IsShow)
  if self:HasPanel("Leve_BattleSilhouette") then
    local PanelInfo = self:GetPanel("Leve_BattleSilhouette")
    if PanelInfo then
      PanelInfo:ShowOrHidePanel(_IsShow)
    end
  end
end

function LevelSelectionModule:OnCmdCloseBattleTeamPanel()
  if self:HasPanel("Leve_BattleTeam") then
    local panel = self:GetPanel("Leve_BattleTeam")
    panel:OnClosePanel()
    if self:HasPanel("Leve_BattleArray") then
      local ArrayPanel = self:GetPanel("Leve_BattleArray")
      ArrayPanel:OnCloseBattleTeamView()
    end
  end
end

function LevelSelectionModule:OnCmdOpenRulePanel(activityId, ruleIds)
  self:OpenPanel("Leve_Rule", activityId, ruleIds)
end

function LevelSelectionModule:OnCmdOpenLevelFirstPublishPanel(...)
  self:OpenPanel("LevelFirstPublish", ...)
end

function LevelSelectionModule:OnCmdCloseLevelFirstPublishPanel(...)
  self:ClosePanel("LevelFirstPublish", ...)
end

function LevelSelectionModule:OnCmdGetAllTeamDatas()
  return self.data.allTeamDataList
end

function LevelSelectionModule:OnCmdGetCacheTeamData()
  return self.data.cacheTeamData
end

function LevelSelectionModule:OnCmdSetCacheTeamData(selectTeam)
  self.data.cacheTeamData = selectTeam
end

function LevelSelectionModule:OnCmdInitCurrentTeamDic(teamData, isFormation)
  self.currentTeamDic = {}
  self.isFormation = isFormation
  for i = 1, 6 do
    if teamData.teams and i <= #teamData.teams then
      self.currentTeamDic[i] = teamData.teams[i].pet_gid
    else
      self.currentTeamDic[i] = 0
    end
  end
end

function LevelSelectionModule:GetPetDataSelectIdx(gid)
  if self.currentTeamDic == nil then
    return 0
  end
  for idx, petGid in pairs(self.currentTeamDic) do
    if petGid == gid then
      return idx
    end
  end
  return 0
end

function LevelSelectionModule:OnCmdCompileCurrentTeam(pet_gid, isUpdatePetList)
  local selectIdx = 0
  local isHave = false
  for idx, gid in pairs(self.currentTeamDic) do
    if gid == pet_gid then
      self.currentTeamDic[idx] = 0
      selectIdx = 0
      isHave = true
      break
    end
  end
  if not isHave then
    for idx, gid in pairs(self.currentTeamDic) do
      if 0 == gid then
        self.currentTeamDic[idx] = pet_gid
        selectIdx = idx
        break
      end
    end
  end
  if self.isFormation then
    self:DispatchEvent(LevelSelectionModuleEvent.OnChangeMainTeamSelectPet, self.currentTeamDic)
  else
    self:DispatchEvent(LevelSelectionModuleEvent.OnChangeSelectPet, self.currentTeamDic)
  end
  if isUpdatePetList then
    self:DispatchEvent(LevelSelectionModuleEvent.OnUpdateCurrentPetList)
  end
  return selectIdx
end

function LevelSelectionModule:OnCmdSaveBattleTeam(curSelectTeam)
  self:SendZonePetTeamChangeReq(curSelectTeam)
end

function LevelSelectionModule:OnCmdStartBattle(activeId, levelId, moduleId, petGid)
  self:SendZoneChallengeCreateBattleReq(activeId, levelId, moduleId, petGid)
end

function LevelSelectionModule:OnCmdSelectTeam(curSelectTeamInfo, panelType)
  self:SendZonePetTeamChangeApplicationReq(curSelectTeamInfo, panelType)
end

function LevelSelectionModule:OnCmdReplaceRuleBuffId(activiyId, ruleId)
  self:SendZoneChallengeSetBuffReqReq(activiyId, ruleId)
end

function LevelSelectionModule:SendZoneChallengeSetBuffReqReq(activiyId, ruleId)
  local req = _G.ProtoMessage:newZoneChallengeSetBuffReq()
  req.activity_id = activiyId
  req.buff_rule_id = ruleId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHALLENGE_SET_BUFF_REQ, req, self, self.OnZoneChallengeSetBuffRsp, false, false)
end

function LevelSelectionModule:OnZoneChallengeSetBuffRsp(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.buff_rule_id then
    self:DispatchEvent(LevelSelectionModuleEvent.OnReplaceRuleSucceed, rsp.buff_rule_id)
  end
end

function LevelSelectionModule:SendZonePetTeamChangeReq(curSelectTeam)
  local team = _G.ProtoMessage:newPetTeam()
  team.role_magic_gid = curSelectTeam.magicGid
  team.team_name = curSelectTeam.title
  team.pet_infos = {}
  for key, value in pairs(curSelectTeam.teams) do
    if 0 ~= value.pet_gid then
      table.insert(team.pet_infos, value)
    end
  end
  local req = _G.ProtoMessage:newZonePetTeamChangeReq()
  req.team_type = curSelectTeam.type
  req.team_idxs = {}
  table.insert(req.team_idxs, curSelectTeam.idx)
  req.teams = {}
  table.insert(req.teams, team)
  if curSelectTeam.type == _G.Enum.PlayerTeamType.PTT_PVE_NPC_CHALLENGE_FIGHT or curSelectTeam.type == _G.Enum.PlayerTeamType.PTT_PVE_BOSS_CHALLENGE_FIGHT then
    self.IsCurrentTeam = true
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_CHANGE_REQ, req, self, self.OnZonePetTeamChangeRsp, false, false)
end

function LevelSelectionModule:OnZonePetTeamChangeRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:CreateDefaultTeamDatas()
    self:DispatchEvent(LevelSelectionModuleEvent.OnSaveBattleTeamSucceed, self.IsCurrentTeam)
  else
    Log.Error("\228\191\157\229\173\152\231\188\150\233\152\159\229\164\177\232\180\165")
  end
  self.IsCurrentTeam = false
end

function LevelSelectionModule:SendZonePetTeamChangeApplicationReq(curSelectTeam, panelType)
  local team = _G.ProtoMessage:newPetTeam()
  team.role_magic_gid = curSelectTeam.magicGid
  team.team_name = curSelectTeam.title
  team.pet_infos = {}
  for key, value in pairs(curSelectTeam.teams) do
    if 0 ~= value.pet_gid then
      table.insert(team.pet_infos, value)
    end
  end
  local req = _G.ProtoMessage:newZonePetTeamChangeReq()
  req.team_type = curSelectTeam.type
  if panelType then
    if panelType == LevelSelectionEnum.BattlePanel.Silhouette then
      req.team_type = _G.Enum.PlayerTeamType.PTT_PVE_NPC_CHALLENGE_FIGHT
    else
      req.team_type = _G.Enum.PlayerTeamType.PTT_PVE_BOSS_CHALLENGE_FIGHT
    end
    curSelectTeam.idx = 0
  end
  Log.Error("\229\186\148\231\148\168\231\188\150\233\152\159", req.team_type, curSelectTeam.idx, #curSelectTeam.teams)
  req.team_idxs = {}
  table.insert(req.team_idxs, curSelectTeam.idx)
  req.teams = {}
  table.insert(req.teams, team)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_CHANGE_REQ, req, self, self.OnZonePetTeamChangeApplicationRsp, false, false)
end

function LevelSelectionModule:OnZonePetTeamChangeApplicationRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:CreateDefaultTeamDatas()
    self:DispatchEvent(LevelSelectionModuleEvent.OnApplicationBattleTeamSucceed)
  else
    Log.Error("\229\186\148\231\148\168\231\188\150\233\152\159\229\164\177\232\180\165")
  end
end

function LevelSelectionModule:SendZoneChallengeCreateBattleReq(activity_id, level_id, module_id, priority_pet_gid)
  local req = ProtoMessage:newZoneChallengeCreateBattleReq()
  req.source_data = ProtoMessage:newSourceData()
  req.source_data.source_type = _G.ProtoEnum.EClientBattleSourceType.ECBST_NPC_CHALLENGE
  req.source_data.activity_id = activity_id
  req.priority_pet_gid = priority_pet_gid
  req.source_data.challenge_level_id = level_id
  if not module_id then
    req.dungeon_id = _G.DataConfigManager:GetChallengeGlobalConf(1).num
    req.source_data.source_type = _G.ProtoEnum.EClientBattleSourceType.ECBST_BOSS_CHALLENGE
  end
  Log.Error(req.source_data.activity_id, req.source_data.challenge_level_id, req.source_data.challenge_module_id, req.dungeon_id)
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    req.avatar_pt = localPlayer:GetServerPoint()
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHALLENGE_CREATE_BATTLE_REQ, req, self, self.OnZoneChallengeCreateBattleRsp, false, false)
end

function LevelSelectionModule:OnZoneChallengeCreateBattleRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    if self:HasPanel("Leve_BattleArray") then
      local panel = self:GetPanel("Leve_BattleArray")
      panel:OnClosePanel()
    end
    if self:HasPanel("Leve_BattleTeam") then
      local panel = self:GetPanel("Leve_BattleTeam")
      panel:OnClosePanel()
    end
  end
end

function LevelSelectionModule:SendZonePetChangeMainTeamReq(curSelectTeamInfo)
  local req = ProtoMessage:newZonePetChangeMainTeamReq()
  req.team_type = curSelectTeamInfo.type
  req.main_team_idx = curSelectTeamInfo.idx
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_CHANGE_MAIN_TEAM_REQ, req, self, self.OnZonePetChangeMainTeamRsp, false, false)
end

function LevelSelectionModule:OnZonePetChangeMainTeamRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    if self.cachedBattleInfo then
      self:SendZoneChallengeCreateBattleReq(self.cachedBattleInfo.activeId, self.cachedBattleInfo.levelId, self.cachedBattleInfo.moduleId)
    end
  else
    Log.Error("\230\140\135\229\174\154\228\189\156\230\136\152\233\152\159\228\188\141\229\164\177\232\180\165", rsp.ret_info.ret_code)
  end
  self.cachedBattleInfo = nil
end

function LevelSelectionModule:UpdateBloodLineMagic()
  self.data:CreateDefaultTeamDatas()
  self:DispatchEvent(LevelSelectionModuleEvent.OnUpdateTeamBloodMagic)
end

function LevelSelectionModule:OnCmdGetCurSelectRuleBuffId()
  return self.data:GetCurSelectRuleBuffId()
end

function LevelSelectionModule:OnCmdSetCurSelectRuleBuffId(id)
  self.data:SetCurSelectRuleBuffId(id)
end

function LevelSelectionModule:RegPanel(name, path, layer, customDisableRendering, openAnimName, closeAnimName)
  local MainPanelData = _G.NRCPanelRegisterData()
  MainPanelData.panelName = name
  MainPanelData.panelPath = string.format("/Game/NewRoco/Modules/System/LevelSelection/Res/%s", path)
  MainPanelData.panelLayer = layer
  if openAnimName then
    MainPanelData.openAnimName = openAnimName
  end
  if closeAnimName then
    MainPanelData.closeAnimName = closeAnimName
  end
  MainPanelData.customDisableRendering = customDisableRendering or false
  self:RegisterPanel(MainPanelData)
end

function LevelSelectionModule:SetLeveBattleSilhouetteIndex(index)
  if not self:HasPanel("Leve_BattleSilhouette") then
    self:OnCmdOpenLeveBattleSilhouette(nil, index)
  end
  if self:HasPanel("Leve_BattleSilhouette") then
    local panel = self:GetPanel("Leve_BattleSilhouette")
    panel:SetSwitcherIndex(index)
  end
end

function LevelSelectionModule:OnMainUIOpen()
  BattleBossChallengeUtils.ShowAdditionalTarget()
end

function LevelSelectionModule:OnMainUIClose()
  BattleBossChallengeUtils.HideAdditionalTarget()
end

function LevelSelectionModule:OnEnterSceneFinishNtyAckEnd(notify, isReconnecting, isEnteringCell, preMapId, mapID)
  BattleBossChallengeUtils.ShowAdditionalTarget()
  if preMapId and mapID and _G.BattleBossChallengeUtils.CheckCurMapIsLeaderChallengeDungeon(preMapId) and 103 == mapID then
    if self.WillOpenLeveSelect then
      self.WillOpenLeveSelect = nil
      _G.NRCModuleManager:DoCmd(LevelSelectionModuleCmd.OpenLeveSelect)
    end
  else
    self.WillOpenLeveSelect = nil
  end
end

function LevelSelectionModule:OnCmdTryOpenLeveBattleSilhouette()
  if self.WillOpenLeveBattleSilhouette then
    self.WillOpenLeveBattleSilhouette = nil
    _G.NRCModuleManager:DoCmd(LevelSelectionModuleCmd.OpenLeveBattleSilhouette)
  end
end

function LevelSelectionModule:OnEnterSceneFinishNtyAck(notify, isReconnecting, isEnteringCell)
end

function LevelSelectionModule:OnCmdSelectLevelTab(_data, Index)
  self:DispatchEvent(LevelSelectionModuleEvent.SelectLevelTabEvent, _data, Index)
end

function LevelSelectionModule:OnCmdChallengeSetModuleUnlock(ActivityId, ModuleId)
  local req = ProtoMessage:newZoneChallengeSetModuleUnlockReadedReq()
  req.activity_id = ActivityId
  req.module_id = ModuleId
  self.ModuleId = ModuleId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHALLENGE_SET_MODULE_UNLOCK_READED_REQ, req, self, self.OnZoneChallengeSetModuleUnlockReadEdRsp, false, false)
end

function LevelSelectionModule:OnZoneChallengeSetModuleUnlockReadEdRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.NPCChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_NPC_CHALLENGE_EVENT)
    if self.NPCChallengeEventActivityObject and self.NPCChallengeEventActivityObject[1] then
      self.NPCChallengeEventActivityObject[1]:ChallengeSetModuleUnlockReadEd(self.ModuleId)
    end
  end
end

function LevelSelectionModule:OnOpenLeaveBossChallengePanel()
  _G.NRCAudioManager:PlaySound2DAuto(1067, "InstanceModule:OnOpenLeavePanel")
  Log.Debug("InstanceModule: OnOpenLeavePanel")
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.inputComponent:SetInputEnable(self, false)
  localPlayer.inputComponent:SetCameraControlEnable(self, false)
  local Nomen = ""
  local Lconf
  local msg = ""
  local Dconf = self:GetDungeonConf(self:GetCurrentDungeon())
  if Dconf then
    Nomen = Dconf.name
    msg = string.format(LuaText.Dung_Leave_Once, Dconf.name)
  end
  OpenMessageBoxWthCaller(Nomen, msg, LuaText.instancemodule_1, LuaText.instancemodule_2, DialogContext.Mode.OK_CANCEL, self.OnCloseLeavePanel, self, nil, true)
end

function LevelSelectionModule:GetDungeonConf(Did)
  local Dconf = _G.DataConfigManager:GetDungeonConf(Did, true)
  if Dconf then
    return Dconf
  else
    Log.Debug("InstanceModule: Dungeon Not Found ", Did)
    return nil
  end
end

function LevelSelectionModule:GetCurrentDungeon()
  if _G.DataModelMgr.PlayerDataModel.playerInfo.common_info.in_dungeon_id then
    return _G.DataModelMgr.PlayerDataModel.playerInfo.common_info.in_dungeon_id[1]
  end
  return self.CurrentDungeon
end

function LevelSelectionModule:OnReconnect()
  self.WillOpenLeveSelect = nil
  self.WillOpenLeveBattleSilhouette = nil
  if self:HasPanel("Leve_BattleSilhouette") then
    self:ClosePanel("Leve_BattleSilhouette")
  end
  if self:HasPanel("Leve_Select") then
    self:ClosePanel("Leve_Select")
  end
end

function LevelSelectionModule:OnCmdSetWillOpenLeveSelect()
  self.WillOpenLeveSelect = true
end

function LevelSelectionModule:OnCmdSetLeveBattleSilhouette()
  self.WillOpenLeveBattleSilhouette = true
end

function LevelSelectionModule:OnCmdGetPanelState(panelName)
  if self:HasPanel(panelName) then
    return true
  end
  return false
end

function LevelSelectionModule:IsHasLevelSelectionTeams(petGid)
  local HasLevelSelectionTeamTypes = {
    _G.Enum.PlayerTeamType.PTT_PVE_CHALLENGE_ALTER,
    _G.Enum.PlayerTeamType.PTT_PVE_NPC_CHALLENGE_FIGHT,
    _G.Enum.PlayerTeamType.PTT_PVE_BOSS_CHALLENGE_FIGHT
  }
  for i = 1, #HasLevelSelectionTeamTypes do
    local type = HasLevelSelectionTeamTypes[i]
    local TeamData = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(type)
    if TeamData then
      for j = 1, #TeamData.teams do
        local curTeam = TeamData.teams[j]
        if curTeam.pet_infos and #curTeam.pet_infos > 0 then
          for k = 1, #curTeam.pet_infos do
            local gid = curTeam.pet_infos[k].pet_gid
            if gid == petGid then
              return true
            end
          end
        end
      end
    end
  end
  return false
end

function LevelSelectionModule:OnCloseLeavePanel(LeaveFlag)
  Log.Debug("LevelSelectionModule: OnCloseLeavePanel ", LeaveFlag)
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.inputComponent:SetInputEnable(self, true)
  localPlayer.inputComponent:SetCameraControlEnable(self, true)
  if _G.BattleManager:IsInBattle() then
    return
  end
  if LeaveFlag then
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.CloseMechanismValidation)
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.CloseBattleAdditionalTarget)
    _G.NRCAudioManager:PlaySound2DAuto(1002, "LevelSelectionModule:OnCloseLeavePanel")
    local ID = _G.DataModelMgr.PlayerDataModel:GetDungeonID()
    if _G.BattleUtils.IsLeaderChallengeDungeon(ID) then
      _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenNpcBattleFailure, nil, true)
    end
  else
    _G.NRCAudioManager:PlaySound2DAuto(1006, "LevelSelectionModule:OnCloseLeavePanel")
  end
end

function LevelSelectionModule:OnCmdSetLevelListItemPet(umg)
  self.CacheLevelListItem = umg
end

function LevelSelectionModule:OnCmdGetLevelListItemPet()
  return self.CacheLevelListItem
end

return LevelSelectionModule
