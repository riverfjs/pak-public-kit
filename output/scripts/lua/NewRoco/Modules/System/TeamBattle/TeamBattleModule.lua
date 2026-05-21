local TeamBattleModule = NRCModuleBase:Extend("TeamBattleModule")
local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")
local TeamBattleModuleEnum = require("NewRoco.Modules.System.TeamBattle.TeamBattleModuleEnum")
local TeamBattleModuleEvent = require("NewRoco.Modules.System.TeamBattle.TeamBattleModuleEvent")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UIUtils = require("NewRoco.Utils.UIUtils")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")

function TeamBattleModule:OnConstruct()
  _G.TeamBattleModuleCmd = reload("NewRoco.Modules.System.TeamBattle.TeamBattleModuleCmd")
  self.data = self:SetData("TeamBattleModuleData", "NewRoco.Modules.System.TeamBattle.TeamBattleModuleData")
  self:AddEventListener()
  self:RegPanel("PreWarInformation", "UMG_PrewarInformation", _G.Enum.UILayerType.UI_LAYER_POPUP, "PanelIn", "PanelOut", true, true)
  self:RegPanel("PreWarConfirmation", "UMG_PrewarConfirmation", _G.Enum.UILayerType.UI_LAYER_POPUP, "PanelIn", "PanelOut")
  self:RegPanel("PreparationPanel", "UMG_TeamBattle_Preparation", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true, true, true)
  self:RegPanel("ChangePetPanel", "UMG_TeamBattle_ChangePet", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true, true, true)
  self:RegPanel("PetTips", "UMG_TeamBattle_PetTips", _G.Enum.UILayerType.UI_LAYER_POPUP, "PanelIn", "PanelOut")
  self:RegisterCmd(TeamBattleModuleCmd.SendZoneTeamBattleInfoQueryReq, self.OnSendZoneTeamBattleInfoQueryReq)
  self.StartTime = 0
  self.CountDownTime = _G.DataConfigManager:GetGlobalConfigByKeyType("team_battle_owner_wait_time", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num
  self.LeftTime = 0
  self.HintLeftTime = 0
  self.ShowBtnCountDownTime = _G.DataConfigManager:GetGlobalConfigByKeyType("team_battle_urgent_time", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num
  self.ShowBtnTime = false
  self.teamBattleAction = nil
  self.CurChallengeType = 0
  self.mateSyncNotifyInfo = nil
end

function TeamBattleModule:OnPlayerDataUpdate()
  self:DispatchEvent(TeamBattleModuleEvent.StarNumChange)
end

function TeamBattleModule:OnLobbyMainReady()
end

function TeamBattleModule:OnReLoginUpdate()
  self:DispatchEvent(TeamBattleModuleEvent.StarNumChange)
end

function TeamBattleModule:OnActive()
end

function TeamBattleModule:OnRelogin()
end

function TeamBattleModule:OnDeactive()
end

function TeamBattleModule:OnDestruct()
  self:RemoveEventListener()
  self.teamBattleAction = nil
end

function TeamBattleModule:OnTick(deltaTime)
  self.LeftTime = self.CountDownTime - (_G.ZoneServer:GetServerTime() / 1000 - self.StartTime)
  if self.LeftTime <= self.ShowBtnCountDownTime then
    self.ShowBtnTime = true
  else
    self.ShowBtnTime = false
  end
  self.HintLeftTime = self.HintLeftTime - deltaTime
  if self.HintLeftTime < 0 and self.LeftTime < 0 then
    UpdateManager:UnRegister(self)
  end
end

function TeamBattleModule:AddEventListener()
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_INVITE_NOTIFY, self.OnZoneTeamBattleInviteNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_INVITE_RESULT_NOTIFY, self.OnZoneTeamBattleInviteResultNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_CANCEL_NOTIFY, self.OnTeamBattleCancelNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_MATE_SYNC_NOTIFY, self.OnZoneTeamBattleMateSyncNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_START_NOTIFY, self.OnZoneTeamBattleStartNotify)
  _G.NRCEventCenter:RegisterEvent("TeamBattleModule", self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingUIClose)
  _G.NRCEventCenter:RegisterEvent("TeamBattleModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
  _G.NRCEventCenter:RegisterEvent("TeamBattleModule", self, SceneEvent.LoadMapStart, self.OnLoadMapStart)
end

function TeamBattleModule:RemoveEventListener()
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_INVITE_NOTIFY, self.OnZoneTeamBattleInviteNotify)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_INVITE_RESULT_NOTIFY, self.OnZoneTeamBattleInviteResultNotify)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_CANCEL_NOTIFY, self.OnTeamBattleCancelNotify)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_MATE_SYNC_NOTIFY, self.OnZoneTeamBattleMateSyncNotify)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_START_NOTIFY, self.OnZoneTeamBattleStartNotify)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingUIClose)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapStart, self.OnLoadMapStart)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
end

function TeamBattleModule:OpenPreWarInfoPanel(challengeType, param, bOwner)
  self:CloseOtherPanel()
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnInVisible)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    localPlayer:ForceSendMoveReq(false, nil)
  end
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenOrCloseMainUIDownTips, false, "OpenTeamBattlePreWarInfo")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  self:OpenPanel("PreWarInformation", challengeType, param, bOwner)
end

function TeamBattleModule:OnLoadMapStart()
  self:ClosePreWarInfoPanel()
end

function TeamBattleModule:ClosePreWarInfoPanel()
  local hasPanel = self:HasPanel("PreWarInformation")
  if hasPanel then
    self:ClosePanel("PreWarInformation")
  end
end

function TeamBattleModule:CmdHasPreWarInformationPanel()
  return self:HasPanel("PreWarInformation") or self:HasPanel("PreWarConfirmation") or self:HasPanel("PreparationPanel") or self:HasPanel("ChangePetPanel") or self.WaitForTeamBattleInfoQueryRsp
end

function TeamBattleModule:CloseOtherPanel()
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_POPUP)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
  NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenPanelLobbyMain)
end

function TeamBattleModule:OpenPreWarConfirmPanel(challengeType, challengeInfo, tips)
  self.CurChallengeType = challengeType
  self:OpenPanel("PreWarConfirmation", challengeType, challengeInfo, tips)
end

function TeamBattleModule:OnCmdClosePreWarConfirmPanel()
  local panel = self:GetPanel("PreWarConfirmation")
  if panel then
    self:ClosePanel("PreWarConfirmation")
  end
end

function TeamBattleModule:OpenTeamBattlePreparationPanel(param, source, challengeType, teamIndex)
  local isOpening, _ = self:HasPanel("PreparationPanel")
  if not isOpening then
    self.singlePlayerModeTogglePetInfoCache = nil
    self:OpenPanel("PreparationPanel", param, challengeType)
  else
    local panel = self:GetPanel("PreparationPanel")
    if panel then
      panel:Enable()
      if 0 == source then
        self.singlePlayerModeTogglePetInfoCache = {
          param = param,
          source = source,
          challengeType = challengeType
        }
        self:OnZoneTeamBattleUpdatePetReq(param.gid, teamIndex)
      else
        panel:RefreshPanelInfo(param, source, challengeType)
      end
    end
  end
end

function TeamBattleModule:OpenTeamBattleChangePetPanel()
  self:OpenPanel("ChangePetPanel")
  local panel = self:GetPanel("PreparationPanel")
  if panel then
    panel:Disable()
  end
end

function TeamBattleModule:OpenPetTipsPanel(petData)
  local isDisableDesc = true
  self:OpenPanel("PetTips", petData, isDisableDesc)
end

function TeamBattleModule:ClosePetTipsPanel()
  local isOpening, _ = self:HasPanel("PetTips")
  if isOpening then
    self:ClosePanel("PetTips")
  end
end

function TeamBattleModule:OnCmdSetHintLeftTime(leftTime)
  self.HintLeftTime = leftTime
  UpdateManager:Register(self)
end

function TeamBattleModule:OnSendZoneTeamBattleInfoQueryReq(npcId, entrance, action)
  NRCProfilerLog:NRCClickBtn(true, "PreWarInformation")
  self.WaitForTeamBattleInfoQueryRsp = true
  local req = _G.ProtoMessage:newZoneSceneTeamBattleInfoQueryReq()
  req.npc_logic_id = npcId
  req.query_source = entrance
  self.teamBattleAction = action
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_INFO_QUERY_REQ, req, self, self.OnZoneTeamBattleInfoQueryRsp)
end

function TeamBattleModule:OnZoneTeamBattleInfoQueryRsp(rsp)
  if self.teamBattleAction then
    self.teamBattleAction:EndAction()
  end
  self.WaitForTeamBattleInfoQueryRsp = false
  Log.Dump(rsp, 5, "TeamBattleModule:OnZoneTeamBattleInfoQueryRsp")
  local retInfo = rsp.ret_info
  local teamBattleInfo = rsp.team_battle_info
  self.teamBattleInfo = teamBattleInfo
  local entrance = rsp.query_source
  if entrance == TeamBattleModuleEnum.EntranceType.NPC then
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    local bVisit = _G.DataModelMgr.PlayerDataModel:IsVisitState()
    local bOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
    if false == bVisit or visitorList and #visitorList <= 1 then
      self:OpenPreWarInfoPanel(_G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE, teamBattleInfo, bOwner)
    else
      self:OpenPreWarInfoPanel(_G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM, teamBattleInfo, bOwner)
      local req = _G.ProtoMessage:newZoneSelectTeamBattleFlowerSeedBossReq()
      req.uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
      req.npc_logic_id = self.teamBattleInfo.npc_logic_id
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SELECT_TEAM_BATTLE_FLOWER_SEED_BOSS_REQ, req, self, self.OnCanSetTeamBattleRsp, true, true)
    end
  end
end

function TeamBattleModule:OnCanSetTeamBattleRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.CanSetTeamBattle = true
    self:SetVisitSelectTeamBattlePetRsp(rsp)
  else
    self.CanSetTeamBattle = false
  end
end

function TeamBattleModule:OnSendZoneTeamBattleChallengeReq(actorId, npcId, challengeType, paramTable, petBloodType)
  local req = _G.ProtoMessage:newZoneSceneTeamBattleChallengeReq()
  self.data.TargetNPCLogicId = npcId
  self.data.TargetNPCActorId = actorId
  req.npc_obj_id = actorId
  req.npc_logic_id = npcId
  req.challenge_type = challengeType
  if petBloodType then
    req.blood_type = petBloodType
  end
  self.CurChallengeType = challengeType
  if challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST or challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE then
    req.battle_cfg_id = paramTable.battleId
  elseif challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_CHALLENGE_REQ, req, self, self.OnZoneTeamBattleChallengeRsp, false, false)
end

function TeamBattleModule:OnZoneTeamBattleChallengeRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.CurChallengeType = rsp.challenge_type
    if rsp.challenge_type == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE or rsp.challenge_type == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE then
      self.data.TeamMateInfoList = rsp.mate_infos
      local NPCHelperNum = 0
      if self.data.TeamMateInfoList then
        self.data.TeamMateInfoList.NPCHelper = {}
        for i, mateInfo in ipairs(self.data.TeamMateInfoList) do
          if 0 ~= mateInfo.helper_id then
            NPCHelperNum = NPCHelperNum + 1
            table.insert(self.data.TeamMateInfoList.NPCHelper, mateInfo)
          end
        end
        self.data.TeamMateInfoList.NPCHelperNum = NPCHelperNum
      end
      self.data.curStage = TeamBattleModuleEnum.PrepareState.Prepared
      self:OpenTeamBattlePreparationPanel()
    else
    end
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_EAM_BATTLE_CANT_TINVITE_VISITOR then
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    local NameList = {}
    local NameString = ""
    for k, v in ipairs(visitorList) do
      for key, val in pairs(rsp.visitors) do
        if v.uin == tonumber(val) then
          table.insert(NameList, v.name)
        end
      end
    end
    for k, v in ipairs(NameList) do
      if 1 == k then
        NameString = v
      else
        NameString = string.format(_G.DataConfigManager:GetLocalizationConf("team_battle_text_1").msg, NameString, v)
      end
    end
    local tips = NameString .. LuaText.teambattlemodule_1
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tips)
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_FUNCTION_BANNED then
    local tips = LuaText.teambattlemodule_2
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tips)
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_BEAST_TOO_HARD then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText["Error_Code_" .. rsp.ret_info.ret_code])
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_VISITOR_FIGHTING then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText["Error_Code_" .. rsp.ret_info.ret_code])
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and rsp.ban_info then
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = rsp.ban_info.uin
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
    local reasonStr = rsp.ban_info.ban_reason or ""
    local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  end
end

function TeamBattleModule:OnZoneTeamBattleConfirmInviteReq(bAgree)
  local req = _G.ProtoMessage:newZoneSceneTeamBattleConfirmInviteReq()
  req.agree = bAgree
  req.challenge_type = self.CurChallengeType
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_CONFIRM_INVITE_REQ, req, self, self.OnZoneTeamBattleConfirmInviteRsp, false, false)
end

function TeamBattleModule:OnZoneTeamBattleConfirmInviteRsp(rsp)
  if rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_NO_TEAMBATTLE then
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_FUNCTION_BANNED then
    local tips = _G.DataConfigManager:GetPetGlobalConfig("team_battle_cant_accept").str
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tips)
  elseif 0 == rsp.ret_info.ret_code then
    self:DispatchEvent(TeamBattleModuleEvent.CloseInformationPanel)
    self.data.curStage = TeamBattleModuleEnum.PrepareState.Preparing
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and rsp.ban_info then
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = rsp.ban_info.uin
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
    local reasonStr = rsp.ban_info.ban_reason or ""
    local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  end
end

function TeamBattleModule:OnZoneTeamBattlePrepareReq(bPrepare)
  local req = _G.ProtoMessage:newZoneSceneTeamBattlePrepareReq()
  req.prepare = bPrepare
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_PREPARE_REQ, req, self, self.OnZoneTeamBattlePrepareRsp, true, true)
end

function TeamBattleModule:OnZoneTeamBattlePrepareRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code and self.teamBattleInfo then
    Log.Error(rsp.ret_info.ret_code, "TeamBattleModule:OnZoneTeamBattlePetQueryRsp")
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function TeamBattleModule:OnZoneTeamBattleUpdatePetReq(petGid, teamIndex)
  local req = _G.ProtoMessage:newZoneSceneTeamBattleUpdatePetReq()
  req.new_pet_gid = petGid
  if teamIndex then
    req.team_idx = teamIndex
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_UPDATE_PET_REQ, req, self, self.OnZoneTeamBattleUpdatePetRsp)
end

function TeamBattleModule:OnZoneTeamBattleUpdatePetRsp(rsp)
  if self.singlePlayerModeTogglePetInfoCache then
    local panel = self:GetPanel("PreparationPanel")
    if panel then
      panel:Enable()
      panel:RefreshPanelInfo(self.singlePlayerModeTogglePetInfoCache.param, self.singlePlayerModeTogglePetInfoCache.source, self.singlePlayerModeTogglePetInfoCache.challengeType)
    end
  end
end

function TeamBattleModule:OnZoneTeamBattlePetQueryReq(_uin, _petGid)
  local uin, petGid
  if type(_uin) == "table" then
    uin = _uin
  elseif type(_uin) == "number" then
    uin = {_uin}
  end
  if type(_petGid) == "table" then
    petGid = _petGid
  elseif type(_petGid) == "number" then
    petGid = {_petGid}
  end
  self.ZoneTeamBattlePetUin = uin
  local req = _G.ProtoMessage:newZoneSceneTeamBattlePetQueryReq()
  req.to_uin = uin
  req.to_gid = petGid
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_PET_QUERY_REQ, req, self, self.OnZoneTeamBattlePetQueryRsp, true, true)
end

function TeamBattleModule:OnZoneTeamBattlePetQueryRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.TeamBattlePetDataList = {}
    for i, v in ipairs(rsp.pet_data) do
      local petData = v
      if self.CurChallengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST or self.CurChallengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE then
        petData.curBattleBaseId = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetBattlePetBaseId)
      elseif self.CurChallengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or self.CurChallengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
        petData.curBattleBaseId = self:GetOwnerSelectTeamBattlePetBaseId()
      end
      petData.uin = self.ZoneTeamBattlePetUin and self.ZoneTeamBattlePetUin[i]
      table.insert(self.TeamBattlePetDataList, petData)
    end
    if (self.CurChallengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or self.CurChallengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE) and not self.teamBattleInfo then
      return
    end
    local fakeDataTable = self.fakeDataTable
    local bOpening = self:OnCmdCheckPreparationPanelOpened()
    if bOpening then
      local panel = self:GetPanel("PreparationPanel")
      panel:RefreshPanelInfo(fakeDataTable, 1)
    else
      self:OpenTeamBattlePreparationPanel(fakeDataTable, nil, self.CurChallengeType)
    end
  else
    Log.Error(rsp.ret_info.ret_code, "TeamBattleModule:OnZoneTeamBattlePetQueryRsp")
    if self.teamBattleInfo then
      local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
    end
  end
end

function TeamBattleModule:GetOwnerSelectTeamBattlePetBaseId()
  if not self.teamBattleInfo then
    return
  end
  if not _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    return self.teamBattleInfo.battle_petbase_id
  end
  if self.teamBattleInfo.select_flower_owner_id then
    Log.Debug("UMG_PrewarInformation_C:SetFlowerSeedFusionInfo", self.teamBattleInfo.select_flower_owner_id)
    local visit_flower_seed_boss_datas = self.teamBattleInfo.visit_flower_seed_boss_datas
    local visit_flower_seed_boss_data
    for i, v in pairs(visit_flower_seed_boss_datas) do
      if v and v.owner_id == self.teamBattleInfo.select_flower_owner_id then
        visit_flower_seed_boss_data = v
        break
      end
    end
    if visit_flower_seed_boss_data then
      return visit_flower_seed_boss_data.inner_petbase_id
    end
  end
  return self.teamBattleInfo.battle_petbase_id
end

function TeamBattleModule:GetTeamBattlePetDataByUin(uin)
  if self.TeamBattlePetDataList and #self.TeamBattlePetDataList > 0 then
    for i, v in ipairs(self.TeamBattlePetDataList) do
      if uin == v.uin then
        return v
      end
    end
  end
end

function TeamBattleModule:OnZoneTeamBattleCancelReq()
  local req = _G.ProtoMessage:newZoneSceneTeamBattleCancelReq()
  self.teamBattleInfo = nil
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_CANCEL_REQ, req, self, self.OnZoneTeamBattleCancelRsp)
end

function TeamBattleModule:OnZoneTeamBattleCancelRsp(rsp)
end

function TeamBattleModule:OnZoneTeamBattleStartReq(npcActorId, npcLogicId, challengeType)
  if self.WaitForTeamBattleStartRsp then
    Log.Debug(self.WaitForTeamBattleStartRsp, "TeamBattleModule:OnZoneTeamBattleStartReq is already waiting for response")
    return
  end
  local req = _G.ProtoMessage:newZoneSceneTeamBattleStartReq()
  req.npc_obj_id = npcActorId
  req.npc_logic_id = npcLogicId
  req.challenge_type = challengeType
  self.WaitForTeamBattleStartRsp = true
  self.delayWaitStartBattleId = _G.DelayManager:DelaySeconds(15, function()
    if self.WaitForTeamBattleStartRsp then
      self.WaitForTeamBattleStartRsp = false
      Log.Error("WaitForTeamBattleStartRsp\228\184\186true\229\183\178\231\187\14315\231\167\146\228\186\134\239\188\140\232\191\152\230\178\161\230\148\182\229\136\176\229\155\158\229\140\133\230\136\150\232\128\133\230\150\173\231\186\191\233\135\141\232\191\158\233\128\154\231\159\165\239\188\140\229\133\136\230\129\162\229\164\141\232\135\170\229\183\177\231\154\132\231\138\182\230\128\129\239\188\140\233\152\178\229\141\161\230\173\187")
    end
  end)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_START_REQ, req, self, self.OnZoneTeamBattleStartRsp)
end

function TeamBattleModule:OnZoneTeamBattleStartRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:ChangeSelectedPet()
  else
    self:SetSelectedBattlePetInfo(nil, nil, nil)
  end
  if self.teamBattleAction then
    self:SendStorageNPCActorId(self.teamBattleAction:GetOwnerNPC().serverData.base.actor_id)
  end
  _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.OnEnterBattleLoading)
  if self.delayWaitStartBattleId then
    _G.DelayManager:CancelDelayById(self.delayWaitStartBattleId)
  end
  self.WaitForTeamBattleStartRsp = false
end

function TeamBattleModule:OnZoneTeamBattleQueryReq()
  local req = _G.ProtoMessage:newZoneSceneTeamBattleQueryReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_QUERY_REQ, req, self, self.OnZoneTeamBattleQueryRsp)
end

function TeamBattleModule:OnZoneTeamBattleQueryRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TeamBattleModuleCmd.SendZoneTeamBattleInfoQueryReq, rsp.flower_logic_id, TeamBattleModuleEnum.EntranceType.NPC)
  else
  end
end

function TeamBattleModule:OnCmdZoneTeamBattleSelectPetReq(selectState)
  local req = _G.ProtoMessage:newZoneSceneTeamBattleSelectPetReq()
  req.select_state = selectState
  local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
  if visitorList and #visitorList > 0 then
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_SELECT_PET_REQ, req, self, self.OnZoneTeamBattleSelectPetRsp)
  end
end

function TeamBattleModule:OnZoneTeamBattleSelectPetRsp(rsp)
end

function TeamBattleModule:OnZoneTeamBattleInviteNotify(notify)
  self.CurChallengeType = notify.challenge_type
  self.StartTime = notify.server_time
  UpdateManager:Register(self)
  local bOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
  if not bOwner then
    if notify.challenge_type == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or notify.challenge_type == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
      _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenApplyVisitInfoHit, 1, notify)
    elseif notify.challenge_type == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST then
      self:OpenPreWarInfoPanel(notify.challenge_type, notify, bOwner)
    end
  elseif notify.challenge_type == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or notify.challenge_type == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
  elseif notify.challenge_type == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST then
  end
  _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.OnReceiveTeamBattleInviteNotify, notify)
end

function TeamBattleModule:SetVisitSelectTeamBattlePet(uin, npc_logic_id)
  if not self.CanSetTeamBattle then
    return
  end
  local req = _G.ProtoMessage:newZoneSelectTeamBattleFlowerSeedBossReq()
  req.uin = uin
  req.npc_logic_id = npc_logic_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SELECT_TEAM_BATTLE_FLOWER_SEED_BOSS_REQ, req, self, self.SetVisitSelectTeamBattlePetRsp)
end

function TeamBattleModule:SetVisitSelectTeamBattlePetRsp(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.uin and rsp.npc_logic_id then
    local visit_flower_seed_boss_datas = self.teamBattleInfo.visit_flower_seed_boss_datas
    self.teamBattleInfo.select_flower_owner_id = rsp.uin
    local visit_flower_seed_boss_data
    if rsp.uin == _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin() then
      visit_flower_seed_boss_data = MagicManualUtils.GetFlowerSeedFusionDataByData(self.teamBattleInfo)
    else
      for i, v in pairs(visit_flower_seed_boss_datas) do
        if v.owner_id == rsp.uin and v.seed_npc_logic_id == rsp.npc_logic_id then
          visit_flower_seed_boss_data = v
          break
        end
      end
    end
    if visit_flower_seed_boss_data then
      self.inner_petbase_id = visit_flower_seed_boss_data.inner_petbase_id
      self.owner_id = visit_flower_seed_boss_data.owner_id
      local hasPanel = self:HasPanel("PreWarInformation")
      if hasPanel then
        local panel = self:GetPanel("PreWarInformation")
        panel:SetVisitSelectTeamBattlePetRsp(visit_flower_seed_boss_data)
      end
    end
  end
end

function TeamBattleModule:ClearFusionInfo(notReq)
  self.owner_id = nil
  self.inner_petbase_id = nil
  if _G.DataModelMgr.PlayerDataModel:IsVisitOwner() and self.teamBattleInfo and not notReq then
    self:SetVisitSelectTeamBattlePet(_G.DataModelMgr.PlayerDataModel:GetPlayerUin(), self.teamBattleInfo.npc_logic_id)
  end
end

function TeamBattleModule:OnZoneTeamBattleInviteResultNotify(notify)
  local uin = notify.uin
  local bAgree = notify.agree
  if bAgree then
  else
    if _G.FunctionBanManager:GetConditionCounter(_G.Enum.PlayerConditionType.PCT_PROP_BLINDBOX) and uin == _G.DataModelMgr.PlayerDataModel:GetPlayerUin() then
    else
      local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
      for k, v in ipairs(visitorList) do
        if v.uin == uin then
          local tips = v.name .. LuaText.teambattlemodule_3
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tips)
        end
      end
    end
    self:ClosePanel("PreWarInformation")
    self:CloseAllPanel()
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.OnCmdClosePlaneExchangeVisitsHint)
  end
end

function TeamBattleModule:OnTeamBattleCancelNotify(notify)
  self.teamBattleInfo = nil
  local uin = notify.uin
  if not notify.overtime then
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    for k, v in ipairs(visitorList) do
      if v.uin == uin and self.LeftTime > 0 then
        local tips = v.name .. LuaText.teambattlemodule_4
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tips)
        self.LeftTime = 0
        self.StartTime = 0
      end
    end
  end
  self:CloseAllPanel()
  self:ClosePanel("PreWarInformation")
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.OnCmdClosePlaneExchangeVisitsHint)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_CloseDialog)
end

function TeamBattleModule:OnLoadingUIClose()
  self:OpenOrRefreshPreparationPanel()
end

function TeamBattleModule:OnReConnect()
  self.WaitForTeamBattleInfoQueryRsp = false
  if self.delayWaitStartBattleId then
    _G.DelayManager:CancelDelayById(self.delayWaitStartBattleId)
  end
  self.WaitForTeamBattleStartRsp = false
  self:OpenOrRefreshPreparationPanel()
end

function TeamBattleModule:OnZoneTeamBattleMateSyncNotify(notify)
  self.mateSyncNotifyInfo = notify
  if notify.sync_reason == _G.ProtoEnum.TeamBattleMateChangeReason.TBMCR_LOGIN then
    self:OpenOrRefreshPreparationPanel()
  else
    if (notify.challenge_type == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or notify.challenge_type == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE) and notify.sync_reason == _G.ProtoEnum.TeamBattleMateChangeReason.TBMCR_PREPARE and not self.teamBattleInfo then
      return
    end
    self:OpenOrRefreshPreparationPanel()
  end
end

function TeamBattleModule:OpenOrRefreshPreparationPanel()
  if self.mateSyncNotifyInfo == nil then
    return
  end
  local notify = self.mateSyncNotifyInfo
  self.mateSyncNotifyInfo = nil
  self.CurChallengeType = notify.challenge_type
  local teamMateInfoList = notify
  local changeUin = 0
  local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
  if teamMateInfoList.sync_reason == _G.ProtoEnum.TeamBattleMateChangeReason.TBMCR_PET then
    local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    if self.data.TeamMateInfoList and #self.data.TeamMateInfoList > 0 then
      for k, v in ipairs(self.data.TeamMateInfoList) do
        if v.uin ~= myUin then
          for key, val in ipairs(teamMateInfoList.mate_infos) do
            if v.uin == val.uin and v.pet_gid ~= val.pet_gid then
              changeUin = v.uin
              break
            end
          end
        end
      end
    end
  end
  if changeUin > 0 then
    for k, v in ipairs(visitorList) do
      if v.uin == changeUin then
        local tips = v.name .. LuaText.teambattlemodule_5
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tips)
        break
      end
    end
    self:ClosePetTipsPanel()
  end
  local fakeDataTable = {}
  for i = 1, #visitorList do
    table.insert(fakeDataTable, {
      uin = visitorList[i].uin,
      prepare_state = _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_NONE,
      pet_cfg_id = 3203,
      pet_gid = nil,
      pet_lv = 0
    })
  end
  if notify.mate_infos and #notify.mate_infos > 0 then
    if teamMateInfoList.sync_reason == _G.ProtoEnum.TeamBattleMateChangeReason.TBMCR_PET then
      if visitorList[1] and teamMateInfoList.update_uin == visitorList[1].uin then
        self.data.TeamMateInfoList = notify.mate_infos
      end
    else
      self.data.TeamMateInfoList = notify.mate_infos
    end
    if self.data.TeamMateInfoList and #self.data.TeamMateInfoList > 0 then
      local NPCHelperNum = 0
      self.data.TeamMateInfoList.NPCHelper = {}
      for i, mateInfo in ipairs(self.data.TeamMateInfoList) do
        if 0 ~= mateInfo.helper_id then
          NPCHelperNum = NPCHelperNum + 1
          table.insert(self.data.TeamMateInfoList.NPCHelper, mateInfo)
        end
      end
      self.data.TeamMateInfoList.NPCHelperNum = NPCHelperNum
    end
    for i = 1, #fakeDataTable do
      for k, v in ipairs(notify.mate_infos) do
        if v.uin == fakeDataTable[i].uin then
          fakeDataTable[i].prepare_state = v.prepare_state
          fakeDataTable[i].pet_cfg_id = v.pet_cfg_id
          fakeDataTable[i].pet_gid = v.pet_gid
          fakeDataTable[i].pet_lv = v.pet_lv
          fakeDataTable[i].mutation_type = v.mutation_type
          fakeDataTable[i].glass_info = v.glass_info
        end
      end
    end
  end
  local uin = {}
  local gid = {}
  for i, v in ipairs(fakeDataTable) do
    if v.pet_gid then
      table.insert(uin, v.uin)
      table.insert(gid, v.pet_gid)
    end
  end
  if #uin > 0 and #gid > 0 then
    self:OnZoneTeamBattlePetQueryReq(uin, gid)
    self.fakeDataTable = fakeDataTable
  else
    local bOpening = self:OnCmdCheckPreparationPanelOpened()
    if bOpening then
      local panel = self:GetPanel("PreparationPanel")
      panel:RefreshPanelInfo(fakeDataTable, 1)
    else
      self:OpenTeamBattlePreparationPanel(fakeDataTable, nil, notify.challenge_type)
    end
  end
end

function TeamBattleModule:OnCmdCheckPreparationPanelOpened()
  local isOpening, _ = self:HasPanel("PreparationPanel")
  return isOpening
end

function TeamBattleModule:OnZoneTeamBattleStartNotify(notify)
  self:ChangeSelectedPet()
  local panel1 = self:GetPanel("ChangePetPanel")
  if panel1 then
    panel1:OnClose()
  end
end

function TeamBattleModule:ChangeSelectedPet()
  if self.battleTeamIndex and self.battlePetIndex and self.battleGid then
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.battleGid)
    if petData then
      _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetSelectPetIndex, self.battlePetIndex, petData)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetSelectIndex, self.battlePetIndex)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.PET, petData)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, self.battleGid)
    end
  end
  self:SetSelectedBattlePetInfo(nil, nil, nil)
end

function TeamBattleModule:SetSelectedBattlePetInfo(teamIndex, petIndex, gid)
  self.battleTeamIndex = teamIndex
  self.battlePetIndex = petIndex
  self.battleGid = gid
end

function TeamBattleModule:SendStorageNPCActorId(actorId)
  local List = _G.ProtoMessage:newTeamBattleNPC()
  List.actor_id = actorId
  _G.DataModelMgr.RemoteStorage:Set("ActorId", ".Next.TeamBattleNPC", List, self, self.OnSetResult)
end

function TeamBattleModule:OnSetResult(rsp)
  Log.Debug("TeamBattleModule:OnSetResult")
end

function TeamBattleModule:GetStorageNPCActorId()
  _G.DataModelMgr.RemoteStorage:Get("ActorId", ".Next.TeamBattleNPC", self, self.OnGetContent)
end

function TeamBattleModule:OnGetContent(rsp)
  local actorId = rsp.actor_id
  local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, actorId)
  npc.viewObj:PlayDisappearSkill1()
end

function TeamBattleModule:ClearTeamMateInfoList()
  self.data.TeamMateInfoList = nil
end

function TeamBattleModule:CheckEnterCondition(challengeType)
  local StarChainOK = false
  local BallOK = false
  local BothOK = false
  if challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
    local NeedStarChainNum = _G.DataConfigManager:GetGlobalConfigByKeyType("team_battle_starlink", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num
    StarChainOK = NeedStarChainNum <= _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
    local StarDebris = NeedStarChainNum <= _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR_DEBRIS)
    StarChainOK = StarChainOK or StarDebris
    BallOK = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemNumByType, _G.Enum.BagItemType.BI_PET_BALL) > 0
  elseif challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST or challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE then
    local needStarChainNum = _G.DataConfigManager:GetLegendaryGlobalConfig("star_consume").num
    local costItemId, needTicketNum = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetLegendaryTicketIDAndNum)
    local checkCoinInfos = {
      {
        UIUtils.CheckCoinType.CI_BagItem,
        costItemId,
        needTicketNum
      },
      {
        UIUtils.CheckCoinType.CI_VisualItem,
        Enum.VisualItem.VI_STAR,
        needStarChainNum
      }
    }
    local enoughCoinTable = UIUtils.CheckEnterCondition(checkCoinInfos)
    for k, v in ipairs(enoughCoinTable) do
      if v.CheckType == UIUtils.CheckCoinType.CI_BagItem then
        BallOK = true
      elseif v.CheckType == UIUtils.CheckCoinType.CI_VisualItem then
        StarChainOK = true
      end
    end
  end
  BothOK = BallOK and StarChainOK
  if BothOK then
    return TeamBattleModuleEnum.EnterConditionState.BothOK
  elseif StarChainOK then
    return TeamBattleModuleEnum.EnterConditionState.OnlyStarChainOK
  elseif BallOK then
    return TeamBattleModuleEnum.EnterConditionState.OnlyBallOK
  else
    return TeamBattleModuleEnum.EnterConditionState.None
  end
end

function TeamBattleModule:OnCmdGetTeamBattleAwards(star, blood)
  return self.data:GetTeamBattleAwards(star, blood)
end

function TeamBattleModule:OnCmdGetEnterTeamBattleType()
  local bVisit = _G.DataModelMgr.PlayerDataModel:IsVisitState()
  if bVisit then
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    if #visitorList > 1 then
      return true
    else
      return false
    end
  else
    return false
  end
end

function TeamBattleModule:OnCmdSetChangePetPanelChoosePet(petData)
  self.data:SetChangePetPanelChoosePet(petData)
end

function TeamBattleModule:OnCmdSetCurChoosePet(petGid)
  self.data:SetCurChoosePet(petGid)
end

function TeamBattleModule:OnCmdOpenTeamBattleStartConfirmTips(IsDebug)
  self.IsDebug = IsDebug
  local title = LuaText.teambattlemodule_6
  local des = _G.DataConfigManager:GetGlobalConfigByKeyType("team_battle_single_or_team", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).str
  if self.owner_id and self.owner_id ~= _G.DataModelMgr.PlayerDataModel:GetPlayerUin() then
    local visitInfo = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorByUin, self.owner_id)
    local FusionText = string.format(LuaText.team_battle_visit_add_text, visitInfo and visitInfo.name or "")
    des = string.format([[
%s
%s]], des, FusionText)
  end
  local leftText = LuaText.teambattlemodule_7
  local rightText = LuaText.teambattlemodule_8
  local Context = DialogContext()
  Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.ConfirmBattleType):SetCloseOnOK(false):SetCloseOnCancel(true):SetButtonText(rightText, leftText)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
end

function TeamBattleModule:ConfirmBattleType(bTeam)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_CloseDialog)
  if bTeam then
    if self.IsDebug then
      self.IsDebug = false
      return
    end
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    if #visitorList > 1 then
      self:ConfirmStartTeamBattle()
    else
      self:ConfirmStartSingleBattle()
    end
  else
    self:ConfirmStartSingleBattle()
  end
end

function TeamBattleModule:GetFusionInfoByUin(uin)
  local visit_flower_seed_boss_datas = self.teamBattleInfo and self.teamBattleInfo.visit_flower_seed_boss_datas
  if visit_flower_seed_boss_datas then
    for i, v in pairs(visit_flower_seed_boss_datas) do
      if v.owner_id == uin then
        return v
      end
    end
  end
end

function TeamBattleModule:ConfirmStartTeamBattle()
  if self.owner_id and self.owner_id ~= _G.DataModelMgr.PlayerDataModel:GetPlayerUin() then
    local visit_flower_seed_boss_data = self:GetFusionInfoByUin(self.owner_id)
    if visit_flower_seed_boss_data then
      self:OnSendZoneTeamBattleChallengeReq(visit_flower_seed_boss_data.seed_npc_obj_id, visit_flower_seed_boss_data.seed_npc_logic_id, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM, nil, visit_flower_seed_boss_data.blood)
    end
    return
  end
  self:OnSendZoneTeamBattleChallengeReq(self.data:GetCurNPCActorId(), self.data.TargetNPCLogicId, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM, nil, self.teamBattleInfo.blood)
end

function TeamBattleModule:CreateTeamBattleOriData()
  local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
  local tempTeamMateInfo = {}
  for i = 1, 4 do
    table.insert(tempTeamMateInfo, {
      uin = 0,
      prepare_state = _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_IDLE,
      pet_cfg_id = 3203,
      pet_gid = nil,
      pet_lv = 0
    })
    if i <= #visitorList then
      if 1 == i then
        tempTeamMateInfo[i].uin = visitorList[i].uin
        tempTeamMateInfo[i].prepare_state = _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_OK
        local petGid = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetSelectedPetGid)
        if petGid <= 0 then
          local teamPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
          for j = 1, #teamPetInfo do
            local hpCur = PetUtils.GetPetAdditionalByType(teamPetInfo[i], _G.ProtoEnum.AttributeType.AT_HPCUR)
            if hpCur > 0 then
              petGid = teamPetInfo[j].gid
              break
            end
          end
        end
        tempTeamMateInfo[i].pet_gid = petGid
        local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
        tempTeamMateInfo[i].pet_cfg_id = petData.base_conf_id
        tempTeamMateInfo[i].pet_lv = petData.level
      else
        tempTeamMateInfo[i].uin = visitorList[i].uin
        tempTeamMateInfo[i].prepare_state = _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_IDLE
      end
    else
      tempTeamMateInfo[i].prepare_state = _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_IDLE
    end
  end
  return tempTeamMateInfo
end

function TeamBattleModule:ConfirmStartSingleBattle()
  if self.owner_id and self.owner_id ~= _G.DataModelMgr.PlayerDataModel:GetPlayerUin() then
    self:SetVisitSelectTeamBattlePet(_G.DataModelMgr.PlayerDataModel:GetPlayerUin(), self.teamBattleInfo.npc_logic_id)
    return
  end
  if self.IsDebug then
    self.IsDebug = false
    self:OpenTeamBattlePreparationPanel(1)
    return
  end
  self:OnSendZoneTeamBattleChallengeReq(self.data:GetCurNPCActorId(), self.data.TargetNPCLogicId, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE, nil, self.teamBattleInfo.blood)
end

function TeamBattleModule:OnCmdGetTeamMateInfoByUin(uin)
  return self.data:GetTeamMateInfoByUin(uin)
end

function TeamBattleModule:OnCmdGetChallengeType()
  return self.CurChallengeType
end

function TeamBattleModule:ClosePanelByName(panelName)
  if self:HasPanel(panelName) then
    local panel = self:GetPanel(panelName)
    if panel then
      panel:DoClose()
    end
  end
end

function TeamBattleModule:TempDisableTeamBattlePanel(bEnable, ExChangeSuccess)
  if bEnable and ExChangeSuccess then
    if self:HasPanel("PreWarConfirmation") then
      self:ClosePanel("PreWarConfirmation")
    end
    if self:HasPanel("PreWarInformation") then
      self:EnablePanel("PreWarInformation")
    end
  elseif nil ~= ExChangeSuccess then
    if self:HasPanel("PreWarConfirmation") then
      self:EnablePanel("PreWarConfirmation")
    end
  else
    self:EnableOrDisableAllPanel(bEnable)
  end
end

function TeamBattleModule:CloseModuleAllPanel()
  self:CloseAllPanel()
end

function TeamBattleModule:OnBattleStart()
end

function TeamBattleModule:OnBattleEnd()
end

function TeamBattleModule:RegPanel(name, path, layer, OpenAnimName, CloseAnimName, isSingleTouchPanel, customDisableRendering, enablePcEsc)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/TeamBattle/Res/%s", path)
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

function TeamBattleModule:OnCmdVisiblePrewarInformationPanel()
  if self:HasPanel("PreWarInformation") then
    self:EnablePanel("PreWarInformation")
  end
  if self:HasPanel("PreWarConfirmation") then
    self:ClosePanel("PreWarConfirmation")
  end
end

return TeamBattleModule
