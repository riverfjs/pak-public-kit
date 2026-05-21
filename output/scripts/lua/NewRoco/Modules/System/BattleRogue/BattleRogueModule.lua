local RogueStateInstFactory = require("NewRoco.Modules.System.BattleRogue.RogueStateInstFactory")
local RogueModuleEnum = require("NewRoco.Modules.System.BattleRogue.RogueModuleEnum")
local ModuleEvent = require("NewRoco.Modules.System.BattleRogue.BattleRogueModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local BattleRogueModule = _G.NRCModuleBase:Extend("BattleRogueModule")

function BattleRogueModule:OnConstruct()
  _G.BattleRogueModuleCmd = reload("NewRoco.Modules.System.BattleRogue.BattleRogueModuleCmd")
  self.Data = self:SetData("BattleRogueModuleData", "NewRoco.Modules.System.BattleRogue.BattleRogueModuleData")
  self.RogueStateInstFactory = RogueStateInstFactory()
  self.CurStateInst = nil
  self.CurState = RogueModuleEnum.RogueStateEnum.None
  self.PreState = RogueModuleEnum.RogueStateEnum.None
  self.TempEventAction = nil
  self.bSkipAsync = false
  self:RegisterAllHerbologyBadgePanel()
  self:AddAllEventListener()
end

function BattleRogueModule:OnDestruct()
  self:RemoveAllEventListener()
end

function BattleRogueModule:RegisterAllHerbologyBadgePanel()
  local RegisterData = _G.NRCPanelRegisterData()
  RegisterData.panelName = "HerbologyBadgeMain"
  RegisterData.panelPath = string.format("/Game/NewRoco/Modules/System/HerbologyBadge/Res/UMG_HerbologyBadge_Main")
  RegisterData.panelLayer = Enum.UILayerType.UI_LAYER_MAIN
  RegisterData.touchCount = 4
  RegisterData.enablePcEsc = false
  self:RegisterPanel(RegisterData)
  self:RegPanel("Entrance", "UMG_HerbologyBadge_Entrance", Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, true, true)
  self:RegPanel("SelectTrial", "UMG_HerbologyBadge_Trial", Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, true, true)
  self:RegPanel("SelectPet", "UMG_HerbologyBadge_SelectPet", Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, true, true)
  self:RegPanel("AffirmPet", "UMG_HerbologyBadge_AffirmPet", Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, true, true)
  self:RegPanel("SelectEnemy", "UMG_HerbologyBadge_SelectOpponent", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, false, false)
  self:RegPanel("Settlement", "UMG_HerbologyBadge_VictorySettlement", Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, true, true)
  self:RegPanel("PeculiarityTips", "UMG_GrassBadge_Peculiarity_Tips", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("ChapterTips", "UMG_HerbologyBadge_TipsChapter", Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, true, true)
  self:RegPanel("TrialTips", "UMG_HerbologyBadge_Tips", Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, true, true)
  self:RegPanel("MonsterInfo", "UMG_HerbologyBadge_ChangePetConfirm", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("DetailedInformation", "UMG_HerbologyBadge_DetailedInformation", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
end

function BattleRogueModule:AddAllEventListener()
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_GRASS_TRIAL_CHALLENGE_DATA_SYNC_NOTIFY, self.OnChallengeDataSyncNotify)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReconnect)
  self:RegisterEvent(self, ModuleEvent.OnNodeFinished, self.OnNodeFinished)
end

function BattleRogueModule:RemoveAllEventListener()
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_GRASS_TRIAL_CHALLENGE_DATA_SYNC_NOTIFY, self.OnChallengeDataSyncNotify)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReconnect)
  self:UnRegisterEvent(self, ModuleEvent.OnNodeFinished)
end

function BattleRogueModule:OnReconnect()
  if self:IsInChallenge() then
    self.bSkipAsync = true
  end
end

function BattleRogueModule:OnChallengeDataSyncNotify(Notify)
  a.task(function()
    self.Data:UpdateChallengeInfo(Notify.challenge_data)
    local Promise = au.CreatePromise()
    _G.NRCEventCenter:RegisterEvent(self.name, self, LoadingUIModuleEvent.LOADING_UI_PRECLOSED, Promise.resolve)
    if not self.bSkipAsync then
      a.wait(Promise.future)
    end
    _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_PRECLOSED, Promise.resolve)
    if Notify.challenge_data.state == Enum.GrassTrialState.GTS_CHALLENGE_LOBBY then
      self:TryChangeState(RogueModuleEnum.RogueStateEnum.ChallengeLobby)
    elseif Notify.challenge_data.state == Enum.GrassTrialState.GTS_CHALLENGE_BATTLE then
      self:TryChangeState(RogueModuleEnum.RogueStateEnum.ChallengeBattle)
      local Npcs = _G.NRCModuleManager:DoCmd(NPCModuleCmd.GetAllNPC)
      for _, NPC in pairs(Npcs) do
        local MainOption = NPC.InteractionComponent:GetOptionByID(8600001)
        if MainOption then
          NPC.viewObj:AddCustomTickDistance(MainOption.config.option_radius + 30)
        end
      end
    end
    local NodeData = Notify.challenge_data.current_selection
    if NodeData and next(NodeData) then
      self:SetPlayerLock(true, "BattleRogueModuleChooseEnemy")
      self.Data.CacheNodeData = Notify.challenge_data.current_selection
    end
  end)()
end

function BattleRogueModule:TryChangeState(NextState, ...)
  if self.CurState == NextState then
    return
  end
  if self.CurStateInst and not self.CurStateInst:CanSwitchState() then
    return
  end
  self.PreState = self.CurStateInst and self.CurStateInst.State or RogueModuleEnum.RogueStateEnum.None
  local Direction = NextState > self.PreState and 1 or -1
  if self.CurStateInst then
    self.CurStateInst:SetTransitionDirection(Direction)
    self.CurStateInst:DoExit()
  end
  self.CurStateInst = self.RogueStateInstFactory:GetStateInst(NextState, ...)
  self.CurState = self.CurStateInst.State
  self.CurStateInst:SetTransitionDirection(Direction)
  self.CurStateInst:DoEnter()
  Log.DebugFormat("[BattleRogueModule] ChangeState:    PreState: %s     CurState: %s", table.getKeyName(RogueModuleEnum.RogueStateEnum, self.PreState), table.getKeyName(RogueModuleEnum.RogueStateEnum, self.CurState))
end

function BattleRogueModule:RegPanel(name, path, layer, openAnimName, closeAnimName, bCustomDisableRendering, enablePcEsc)
  local RegisterData = _G.NRCPanelRegisterData()
  RegisterData.panelName = name
  RegisterData.panelPath = string.format("/Game/NewRoco/Modules/System/HerbologyBadge/Res/%s", path)
  RegisterData.panelLayer = layer
  if openAnimName then
    RegisterData.openAnimName = openAnimName
  end
  if closeAnimName then
    RegisterData.closeAnimName = closeAnimName
  end
  RegisterData.enablePcEsc = enablePcEsc
  RegisterData.customDisableRendering = bCustomDisableRendering or false
  self:RegisterPanel(RegisterData)
end

function BattleRogueModule:OpenExitPanel()
  self:SetPlayerLock(true, "BattleRogueModuleExit")
  local TitleStr = LuaText.TIPS
  local MsgStr = LuaText.grass_trial_exit_info
  OpenMessageBoxWthCaller(TitleStr, MsgStr, LuaText.grass_trial_abandon_challenge, LuaText.grass_trial_pause_challenge, DialogContext.Mode.OK_CANCEL, self.OnCloseExitPanel, self, nil, false, true)
end

function BattleRogueModule:OpenAbandonChallengeTip()
  local TitleStr = LuaText.TIPS
  local MsgStr = LuaText.grass_trial_abandon_info
  OpenMessageBoxWthCaller(TitleStr, MsgStr, LuaText.CONFIRM, LuaText.CANCEL, DialogContext.Mode.OK_CANCEL, self.OnConfirmExit, self, nil, false, true)
end

local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local CloseType = CommonBtnEnum.DialogCancelType

function BattleRogueModule:OnCloseExitPanel(bOk, ECancelType)
  local bAbandon
  if bOk then
    bAbandon = true
  elseif ECancelType == CloseType.BtnClickType then
    bAbandon = false
  else
    bAbandon = nil
  end
  if bAbandon then
    self:OpenAbandonChallengeTip()
  elseif false == bAbandon then
    local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_GRASS_TRIAL_PAUSE_CHALLENGE_REQ
    local Req = ProtoMessage:newZoneGrassTrialPauseChallengeReq()
    ZoneServer:SendWithHandler(Cmd, Req, self, self.OnServerExit)
    self:SetPlayerLock(false, "BattleRogueModuleExit")
  else
    self:SetPlayerLock(false, "BattleRogueModuleExit")
  end
end

function BattleRogueModule:OnConfirmExit(bOk)
  if bOk then
    local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_GRASS_TRIAL_ABANDON_CHALLENGE_REQ
    local Req = ProtoMessage:newZoneGrassTrialAbandonChallengeReq()
    ZoneServer:SendWithHandler(Cmd, Req, self, self.OnServerExit)
  end
  self:SetPlayerLock(false, "BattleRogueModuleExit")
end

function BattleRogueModule:OnServerExit(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    self:TryChangeState(RogueModuleEnum.RogueStateEnum.Exit)
  end
end

function BattleRogueModule:SetPlayerLock(bLock, Flag)
  local LocalPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  LocalPlayer.inputComponent:SetInputEnable(self, not bLock, Flag)
  LocalPlayer.inputComponent:SetCameraControlEnable(self, not bLock)
end

function BattleRogueModule:OpenPeculiarityTips(SkillID, PetBaseConfID)
  local SkillConf = _G.DataConfigManager:GetSkillConf(SkillID)
  local bFeature = SkillConf.type == Enum.SkillActiveType.SAT_FEATURE
  if bFeature then
    local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.Data.TrialPetInfo.pet_gid)
    if PetBaseConfID then
      self:OpenPanel("PeculiarityTips", SkillID, nil, PetBaseConfID)
    else
      self:OpenPanel("PeculiarityTips", SkillID, PetData)
    end
  else
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenBagSKillTips, SkillID, false)
  end
end

function BattleRogueModule:OpenChooseEnemyPanel(Action)
  if self.Data.CacheNodeData then
    local Rsp = ProtoMessage:newZoneGrassTrialNextNodeRsp()
    Rsp.node_selection = self.Data.CacheNodeData
    self:OpenPanel("SelectEnemy", self.Data, Rsp)
  else
    local ParamList = BattleRogueModule:GetReqParamList()
    ParamList.chapter_id = self.Data.CurChapterID
    ParamList.node_index = self.Data.CurNodeIndex
    self:OpenPanelWithReq("SelectEnemy", ProtoCMD.ZoneSvrCmd.ZONE_GRASS_TRIAL_NEXT_NODE_REQ, ProtoMessage.newZoneGrassTrialNextNodeReq())
  end
  self.TempEventAction = Action
  self:SetPlayerLock(true, "BattleRogueModuleChooseEnemy")
end

function BattleRogueModule:OnNodeFinished()
  self:Log("Node Select Finish!")
  self.TempEventAction:Finish(true)
  self.TempEventAction = nil
  self:SetPlayerLock(false, "BattleRogueModuleChooseEnemy")
end

local OpenPanelReq = _G.NRCPanelOpenReqData()

function BattleRogueModule:GetReqParamList()
  if OpenPanelReq.paramList then
    table.clear(OpenPanelReq.paramList)
  else
    OpenPanelReq.paramList = {}
  end
  return OpenPanelReq.paramList
end

function BattleRogueModule:OpenPanelWithReq(PanelName, CmdID, ReqClass)
  OpenPanelReq.cmdId = CmdID
  OpenPanelReq.reqClass = ReqClass
  OpenPanelReq.ignoreErrorTip = false
  self:OpenPanel(PanelName, OpenPanelReq)
end

function BattleRogueModule:OpenMonsterInfoPanel(EventData)
  self:OpenPanel("MonsterInfo", EventData)
end

function BattleRogueModule:EnterTrialScene()
  local Req = ProtoMessage:newZoneGrassTrialEnterSceneReq()
  Req.trial_conf_id = self.Data.TrialID
  Req.chapter_id = self.Data.CurChapterID
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GRASS_TRIAL_ENTER_SCENE_REQ, Req, self, self.OnEnterTrialSceneRsp)
end

function BattleRogueModule:OnEnterTrialSceneRsp(Rsp)
  if 0 ~= Rsp.ret_info.ret_code then
    return
  end
  a.task(function()
    local Promise = au.CreatePromise()
    _G.NRCEventCenter:RegisterEvent(self.name, self, LoadingUIModuleEvent.LOADING_UI_CLOSED, Promise.resolve)
    a.wait(Promise.future)
    self:OpenHerbologyChapterTips()
  end)()
end

function BattleRogueModule:ResumeTrialSceneReq()
  local Req = ProtoMessage:newZoneGrassTrialResumeChallengeReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GRASS_TRIAL_RESUME_CHALLENGE_REQ, Req, self, self.ResumeTrialSceneRsp)
end

function BattleRogueModule:ResumeTrialSceneRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    return
  end
  self.Data:UpdateChallengeInfo(rsp.challenge_data)
  if rsp.challenge_data.state == Enum.GrassTrialState.GTS_CHALLENGE_LOBBY then
    self:TryChangeState(RogueModuleEnum.RogueStateEnum.ChallengeLobby)
  elseif rsp.challenge_data.state == Enum.GrassTrialState.GTS_CHALLENGE_BATTLE then
  end
end

function BattleRogueModule:GetHerbologyPetSkillMapByGid(petGid)
  local skillMap = {}
  local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
  if not (petData and petData.skill) or not petData.skill.skill_data then
    return skillMap
  end
  for _, v in ipairs(petData.skill.skill_data) do
    if v.is_equipped and v.pos > 0 then
      skillMap[v.pos] = v.id
    end
  end
  local selectPetPanel = self:GetPanel("SelectPet")
  if selectPetPanel then
    local confirmPanel = selectPetPanel.ConfirmPanel
    if confirmPanel and confirmPanel.PetSkill then
      for pos = 1, 4 do
        skillMap[pos] = nil
      end
      local cachedSkillId = confirmPanel.PetSkill[petGid]
      if cachedSkillId then
        skillMap[1] = cachedSkillId
      end
    end
  end
  return skillMap
end

function BattleRogueModule:SetHerbologyPetSkill(petGid, posToIdDic)
  self:DispatchEvent(ModuleEvent.OnPetSkillChanged, petGid, posToIdDic)
  _G.NRCEventCenter:DispatchEvent(ModuleEvent.OnPetSkillChanged, petGid, posToIdDic)
end

function BattleRogueModule:UpdatePetCollect(partner_mark)
  self:DispatchEvent(ModuleEvent.OnUpdatePetCollect, partner_mark)
end

function BattleRogueModule:OnUpdatePetData(newPetData)
  local bIsOpening, _ = self:HasPanel("SelectPet")
  if bIsOpening then
    local selectPetPanel = self:GetPanel("SelectPet")
    if selectPetPanel then
      selectPetPanel:OnPetDataUpdate(newPetData)
    end
  end
  local bAffirmOpening, _ = self:HasPanel("AffirmPet")
  if bAffirmOpening then
    local affirmPetPanel = self:GetPanel("AffirmPet")
    if affirmPetPanel and affirmPetPanel.petData and affirmPetPanel.petData.gid == newPetData.gid then
      affirmPetPanel:OnPanelShow()
    end
  end
end

function BattleRogueModule:OpenPetCultivatePanel(petData)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetEnterPetPanelType, PetUIModuleEnum.EnterType.HerbologyBadge)
  _G.NRCModuleManager:DoCmd(_G.CampingModuleCmd.SetIsCultivatePet, true)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetOpenPanelPetData, petData, 1, false)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetOpenPanelPetDataRedPoint)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetOpenPetAttribute, true)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetOpenPetAttribute, true)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenPanelPetMain, {
    subPanelIndex = 4,
    bHideSkill = true,
    bUseOpenPetData = true
  })
end

function BattleRogueModule:OpenHerbologyTrialTips(bNotAutoClose, caller, callback)
  self:OpenPanel("TrialTips", bNotAutoClose, caller, callback)
end

function BattleRogueModule:OpenHerbologyChapterTips(caller, callback)
  self:OpenPanel("ChapterTips", caller, callback)
end

function BattleRogueModule:OpenHerbologyBadgeDetailedInformation()
  self:OpenPanel("DetailedInformation")
end

function BattleRogueModule:IsInChallenge()
  return self.CurState == RogueModuleEnum.RogueStateEnum.ChallengeLobby or self.CurState == RogueModuleEnum.RogueStateEnum.ChallengeBattle
end

function BattleRogueModule:GetTrialPetBaseID()
  local Gid = self.Data.TrialPetInfo.pet_gid
  if Gid then
    local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(Gid)
    return PetData and PetData.base_conf_id or nil
  end
  return nil
end

return BattleRogueModule
