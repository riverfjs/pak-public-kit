local MiniGameModuleEvent = reload("NewRoco.Modules.System.MiniGame.MiniGameModuleEvent")
local MiniGameClockSettings = require("NewRoco.Modules.System.MiniGame.MiniGameClockSettings")
local MapRegionAreaUtil = require("NewRoco.Modules.Core.Scene.Map.MapRegionAreaUtil")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local OnlineState = require("Core.Service.NetManager.OnlineState")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local MiniGameModule = NRCModuleBase:Extend("MiniGameModule")
local MiniGameStage = {
  Init = "Init",
  Perform = "Perform",
  Running = "Running"
}
local TimeOfDay = {
  [Enum.TimeOfDay.TOD_DAWN] = {
    {StartTime = 14400, EndTime = 28800}
  },
  [Enum.TimeOfDay.TOD_DAY] = {
    {StartTime = 28800, EndTime = 57600}
  },
  [Enum.TimeOfDay.TOD_TWILIGHT] = {
    {StartTime = 57600, EndTime = 68400}
  },
  [Enum.TimeOfDay.TOD_EVENING] = {
    {StartTime = 68400, EndTime = 86400},
    {StartTime = 0, EndTime = 14400}
  }
}
local GuideRoadClass = "/Game/NewRoco/Modules/Core/NPC/MiniGame/BP_MiniGame_Guide.BP_MiniGame_Guide_C"

function MiniGameModule:OnConstruct()
  Log.Debug("AllenPee: MiniGameModule: OnConstruct")
  self.data = self:SetData("MiniGameModuleData", "NewRoco.Modules.System.MiniGame.MiniGameModuleData")
  self.ConfigId = -1
  self.BenDist = -1
  self.Time = 0
  self.rdy = false
  self.SceneNPCID = 0
  self.ActionStack = {}
  self.Settings = {}
  self.StarCount = {}
  self.bHasRewardCreated = false
  local MiniGamePanel = _G.NRCPanelRegisterData()
  MiniGamePanel.panelName = "MiniGamePanel"
  MiniGamePanel.panelPath = "/Game/NewRoco/Modules/System/MiniGame/Res/UMG_MiniGame1.UMG_MiniGame1"
  MiniGamePanel.panelLayer = Enum.UILayerType.UI_LAYER_DIALOGUE
  MiniGamePanel.enablePcEsc = false
  self:RegisterPanel(MiniGamePanel)
  local LeavePanel = _G.NRCPanelRegisterData()
  LeavePanel.panelName = "MiniGameModuleLeavePanel"
  LeavePanel.panelPath = "/Game/NewRoco/Modules/System/MiniGame/Res/UMG_MiniGame_GiveUp.UMG_MiniGame_GiveUp"
  self:RegisterPanel(LeavePanel)
  local NightmarePanel = _G.NRCPanelRegisterData()
  NightmarePanel.panelName = "MiniGameModuleNightmarePanel"
  NightmarePanel.panelPath = "/Game/NewRoco/Modules/System/TipsModule/Res/UMG_NightmareSettlement.UMG_NightmareSettlement"
  NightmarePanel.enablePcEsc = false
  self:RegisterPanel(NightmarePanel)
  self.MapRegionAreaUtil = MapRegionAreaUtil()
  _G.NRCEventCenter:RegisterEvent(self.moduleName, self, MiniGameModuleEvent.AddClock, self.AddClock)
  _G.NRCEventCenter:RegisterEvent(self.moduleName, self, _G.NRCGlobalEvent.OnOnlineStateChanged, self.OnOnlineStateChanged)
  _G.NRCEventCenter:RegisterEvent(self.moduleName, self, SceneEvent.OnPreTeleportNotify, self.OnEnterSceneStarted)
  _G.NRCEventCenter:RegisterEvent(self.moduleName, self, BattleEvent.EnterBattle, self.OnEnterBattle)
  self.Stage = MiniGameStage.Init
  self.NightmareType = nil
  self.bNightmare = false
  self.NeedPlayNightmareAction = false
  self.bOpenNightmareFinish = false
  self.NeedPlayNightmareCleanAction = false
  self.NeedFinishGameByCleanAction = false
  self.bTeleporting = false
  self.bDelayReqStart = false
end

function MiniGameModule:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, MiniGameModuleEvent.AddClock, self.AddClock)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnOnlineStateChanged, self.OnOnlineStateChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnPreTeleportNotify, self.OnEnterSceneStarted)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.EnterBattle, self.OnEnterBattle)
end

function MiniGameModule:AddClock(BB)
  self.BigBen = BB
  self.BigBen.luaObj.BlockUpdate = true
end

function MiniGameModule:OnEnterSceneStarted()
  Log.Debug("AllenPee: MiniGameModule: OnEnterSceneStarted")
  self.bTeleporting = true
end

function MiniGameModule:OnOnlineStateChanged(OldState, NewState, DisState)
  Log.Debug("AllenPee: MiniGameModule: OnOnlineStateChanged", OldState, NewState)
  if NewState ~= OnlineState.EnteredCell then
    return
  end
  self.bTeleporting = false
  if self.bDelayReqStart then
    self:Initialization()
  end
  if self.Stage == MiniGameStage.Init and 0 == self.SceneNPCID then
    return
  end
  if not self.Status or self.Status == ProtoEnum.MinigameStatus.MS_TIMEOUT or self.Status == ProtoEnum.MinigameStatus.MS_FINISH or self.Status == ProtoEnum.MinigameStatus.MS_EXIT then
    return
  end
  if not self.TODSuccess then
    Log.Debug("MiniGameModule:RestartTimeOfDay", self.ConfigId)
    self:ChangeTimeOfDay()
  end
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    return
  end
  local Status, _, _ = Player.LogicStatusComponent:GetStatus(ProtoEnum.SpaceActorLogicStatus.SALS_MINI_GAME)
  if Status then
    Log.Debug("MiniGameModule:OnEnterSceneFinished \229\174\162\230\136\183\231\171\175\232\174\164\228\184\186\230\178\161\230\156\137\229\176\143\230\184\184\230\136\143\239\188\140\229\144\142\229\143\176\232\174\164\228\184\186\230\156\137\229\176\143\230\184\184\230\136\143\239\188\140\229\143\175\232\131\189\230\152\175\232\191\152\230\178\161\229\188\128\229\167\139...\230\154\130\228\184\141\229\164\132\231\144\134")
    return
  end
  local FakeExitNotify = ProtoMessage:newSpaceAct_MinigameNotify()
  FakeExitNotify.status = ProtoEnum.MinigameStatus.MS_EXIT
  FakeExitNotify.trigger_npc_obj_id = self.SceneNPCID
  FakeExitNotify.remain_time = 0
  FakeExitNotify.minigame_cfg_id = self.ConfigId
  local FakeProgress = ProtoMessage:newMinigameProgress()
  FakeProgress.value = 0
  FakeExitNotify.progress = {FakeProgress, FakeProgress}
  local BaseData = ProtoMessage:newSpaceBaseData()
  BaseData.space_time_ms = os.msTime()
  self:OnMinigameNotify(FakeExitNotify, nil, BaseData)
  self.SceneNPCID = 0
end

function MiniGameModule:AddClockByDist(BB)
  local Character = BB and BB.sceneCharacter
  local InterComp = Character and Character.InteractionComponent
  local MainOption = InterComp and InterComp:GetFirstOption()
  if MainOption then
    local Config = MainOption.config
    if Config and tonumber(Config.action.action_param1) == self.ConfigId then
      self.BigBen = Character
      Character.MiniGameID = self.ConfigId
    end
  end
  if self.LatentRecovery and self:HasPanel("MiniGamePanel") then
    self:LatentRecovery()
    self.LatentRecovery = nil
  end
end

function MiniGameModule:AddNPC(TriggerNPCID)
  self.SceneNPCID = TriggerNPCID
end

function MiniGameModule:GetNightmareType()
  return self.NightmareType
end

function MiniGameModule:IsInNightmare()
  return self.bNightmare
end

function MiniGameModule:IsOpenNightmareFinish()
  return self.bOpenNightmareFinish
end

function MiniGameModule:SetPlayNightmareAction(NeedPlayAction)
  self.NeedPlayNightmareAction = NeedPlayAction
end

function MiniGameModule:SetOpenNightmareFinish(bFinish)
  self.bOpenNightmareFinish = bFinish
end

function MiniGameModule:NeedPlayNightmareAction()
  return self.NeedPlayNightmareAction
end

function MiniGameModule:SetPlayNightmareCleanAction(NeedPlayAction)
  self.NeedPlayNightmareCleanAction = NeedPlayAction
end

function MiniGameModule:NeedFinishGameByCleanAction()
  return self.NeedFinishGameByCleanAction
end

function MiniGameModule:Initialization()
  if self.bTeleporting then
    self.bDelayReqStart = true
  else
    local MiniRequest = ProtoMessage:newZoneSceneStartMinigameReq()
    MiniRequest.minigame_cfg_id = self.ConfigId
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_START_MINIGAME_REQ, MiniRequest, self, self.OnStartRequestRsp, false, true)
    self.bDelayReqStart = false
  end
  Log.Debug("AllenPee: MiniGameModule:Initialization ", self.bTeleporting)
end

function MiniGameModule:OnEnterBattle()
  if self.Stage == MiniGameStage.Init or self.bNightmare then
    return
  end
  local MiniGameConfig = DataConfigManager:GetMinigameConf(self.ConfigId, true)
  if MiniGameConfig and self.MiniGameConfig.effect_type == Enum.MiniGameType.MINIGAME_BOSS_BATTLE then
    return
  end
  self:Reset()
end

function MiniGameModule:OnStartRequestRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    local BigBen = self.BigBen
    if BigBen then
      local BigBenView = BigBen.viewObj
      if BigBenView then
        if BigBenView.RedLightGreenDark then
          BigBenView:RedLightGreenDark()
        end
        local MiniGameConfig = DataConfigManager:GetMinigameConf(self.ConfigId, true)
        if MiniGameConfig then
          local ClockSetting = self.Settings[self.ConfigId] or MiniGameClockSettings:newMiniGameClockSettings()
          ClockSetting.DurationPer = 9999
          ClockSetting.StartSymbol = 1
          ClockSetting.PlayRate = 1.0 / (MiniGameConfig.time_limit / 0.33)
          ClockSetting.StartPos = 0
          ClockSetting.Reset = false
          ClockSetting.Finish = false
          ClockSetting.Activate = true
          ClockSetting.timeout = false
          ClockSetting.BlockUpdate = false
          self.Settings[self.ConfigId] = ClockSetting
          BigBen.luaObj:ApplySettings()
          self:RecordOwnerClock()
        end
      end
    end
    self.Stage = MiniGameStage.Running
    self:DispatchEvent(MiniGameModuleEvent.tick, true)
  else
    if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_NO_MINIGAME then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("ERR_SCENE_NO_MINIGAME").msg)
    end
    self:Reset()
  end
end

function MiniGameModule:Reset()
  if self.InResetting then
    return
  end
  self.InResetting = true
  if self.RecoveryDelayHandle then
    _G.DelayManager:CancelDelayById(self.RecoveryDelayHandle)
    self.RecoveryDelayHandle = nil
  end
  if self.bIsInCoroutine then
    self.bHaltCoroutine = true
  end
  self.OpenCamera = false
  self.Status = nil
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, false, UE4.EPlayerForceHiddenType.MiniGame)
  _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.SetOnlineTeammateTagVisible, true)
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not _G.BattleManager.isInBattle then
    Player:GetUEController():ReleaseRocoCamera(0)
  end
  NRCEventCenter:DispatchEvent(NRCGlobalEvent.CLOSE_BLACK_SCREEN)
  self:EnablePlayerControl()
  self:DispatchEvent(MiniGameModuleEvent.Exit)
  self:DispatchEvent(MiniGameModuleEvent.End, true)
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_MINI_GAME)
  local MiniGameConfig = DataConfigManager:GetMinigameConf(self.ConfigId, true)
  if MiniGameConfig then
    Log.Debug("==amonsu==MiniGameModule==Reset==DestroyWall", MiniGameConfig.block_id, self.bNightmare)
    _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.DestroyWall, MiniGameConfig.block_id, self.bNightmare)
  end
  NRCEventCenter:DispatchEvent(MiniGameModuleEvent.End)
  self:ClosePanel("MiniGamePanel")
  self:ClosePanel("MiniGameModuleLeavePanel")
  self:ClosePanel("MiniGameModuleNightmarePanel")
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_CloseDialog)
  self.Stage = MiniGameStage.Init
  self.InResetting = false
  local BigBen = self.BigBen
  if BigBen then
    local BigBenView = BigBen.viewObj
    if BigBenView and BigBenView.RedDarkGreenLight then
      BigBenView:RedDarkGreenLight()
    end
  end
  if self.MainPanelOpenedCoroutineCallback then
    self.MainPanelOpenedCoroutineCallback()
    self.MainPanelOpenedCoroutineCallback = nil
  end
end

function MiniGameModule:ShowStartBanner(bNightmare)
  self:DispatchEvent(MiniGameModuleEvent.Start, bNightmare)
  NRCEventCenter:DispatchEvent(MiniGameModuleEvent.Start, bNightmare)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.StartMiniGame)
end

function MiniGameModule:OnRdy()
  self.rdy = true
  for i, A in pairs(self.ActionStack) do
    self:OnMinigameNotify(A.Action, A.Tag, A.BaseData)
  end
  self.ActionStack = {}
end

function MiniGameModule:StartExitCamera()
end

function MiniGameModule:RestoreExitCamera()
end

function MiniGameModule:OpenPanelCoroutine(callback)
  self:OpenPanel("MiniGamePanel")
  self:OpenPanel("MiniGameModuleNightmarePanel")
  self.MainPanelOpenedCoroutineCallback = callback
end

function MiniGameModule:RecordOwnerClock()
  self.OwnerId = self.BigBen.serverData.base.actor_id
end

function MiniGameModule:TeleportPlayerToStart(MiniGameConfig, dontSendMove)
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    return
  end
  local playerController = Player:GetUEController()
  if not playerController then
    return
  end
  local PlayerForward = Player:GetForwardVector()
  playerController:SetControlRotation(PlayerForward:ToRotator())
end

function MiniGameModule:BlendToBigWorldCamera(Time)
  Time = Time or 5
  NRCModuleManager:DoCmd(CameraModuleCmd.PrepareBlendingToBigWorldCamera, Time)
end

function MiniGameModule:StopRide()
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if Player then
    Player:StopRide()
  end
end

function MiniGameModule:CheckShouldHalt()
  if self.bHaltCoroutine and self.bIsInCoroutine then
    return true
  else
    return false
  end
end

function MiniGameModule:OnCoroutineStart()
  self.bHaltCoroutine = false
end

function MiniGameModule:DoHaltCoroutine()
  if self.HasHalted then
    Log.Error("early return 1")
    return
  end
  if not self.bHaltCoroutine then
    Log.Error("early return 2")
    return
  end
  self.HasHalted = true
  self.bHaltCoroutine = false
  self.bIsInCoroutine = false
  NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  Player:GetUEController():ReleaseRocoCamera()
  NRCModuleManager:DoCmd(_G.CameraModuleCmd.EndCameraMotion)
  self:Reset()
  self:MinigameEndDataReset()
end

function MiniGameModule:OnConnected(errorCode)
  local BigBen = self.BigBen
  if BigBen then
    local BigBenView = BigBen.viewObj
    if BigBenView then
      if self.Status == ProtoEnum.MinigameStatus.MS_OPEN then
        if BigBenView.RedLightGreenDark then
          BigBenView:RedLightGreenDark()
        end
      elseif BigBen.luaObj.Finished or self.Status == ProtoEnum.MinigameStatus.MS_FINISH then
        if BigBenView.AllDark then
          BigBenView:AllDark()
        end
      elseif self.Status == nil and BigBenView.RedDarkGreenLight then
        BigBenView:RedDarkGreenLight()
      end
    end
  end
  if not self:IsPlaying() then
    return
  end
  if 0 == errorCode then
    self:Reset()
  end
end

function MiniGameModule:OnDisConnected()
  if self.bIsInCoroutine then
    self.bHaltCoroutine = true
    self.HasHalted = false
    _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, false, UE4.EPlayerForceHiddenType.MiniGame)
    _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.SetOnlineTeammateTagVisible, true)
    local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    Player:GetUEController():ReleaseRocoCamera(1)
    self:Reset()
  end
end

function MiniGameModule:IsPlaying()
  if self.Status == ProtoEnum.MinigameStatus.MS_OPEN or self.Status == ProtoEnum.MinigameStatus.MS_RECOVERY then
    return true
  end
  return false
end

function MiniGameModule:LocalIsPlaying()
  if self:HasPanel("MiniGamePanel") then
    return true
  end
  return false
end

function MiniGameModule:IsOpenCamera()
  return self.OpenCamera
end

function MiniGameModule:OnMinigameNotify(Action, Tag, BaseData)
  self.SceneNPCID = Action.trigger_npc_obj_id
  Log.Debug("AllenPee: MiniGameModule:OnMinigameNotify", self.TimeRemain, Action.remain_time, Action.status, BaseData.space_time_ms / 1000, _G.ZoneServer:GetServerTime() / 1000)
  local remainTime = Action.remain_time
  if Action.status == ProtoEnum.MinigameStatus.MS_RECOVERY or Action.status == ProtoEnum.MinigameStatus.MS_PROGRESS then
    remainTime = math.max(Action.remain_time + BaseData.space_time_ms / 1000 - _G.ZoneServer:GetServerTime() / 1000, 0)
  end
  if Action.progress and #Action.progress > 0 then
    self.StarCount[Action.trigger_npc_obj_id] = Action.progress[1].value
  else
    self.StarCount[Action.trigger_npc_obj_id] = 0
  end
  self.TimeRemain = remainTime
  self.ConfigId = Action.minigame_cfg_id
  self:CheckNightmare()
  if not self.rdy then
    local data = {}
    data.Action = Action
    data.Tag = Tag
    data.BaseData = BaseData
    table.clear(self.ActionStack)
    table.insert(self.ActionStack, data)
    return
  end
  local MiniGameConfig = DataConfigManager:GetMinigameConf(self.ConfigId)
  if MiniGameConfig then
    local RuleConf = DataConfigManager:GetMinigameRuleConf(MiniGameConfig.rule)
    if RuleConf then
      local Flash = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetTrackTask)
      if Flash and Flash.Trackers and "table" == type(Flash.Trackers) then
        for _, tracker in pairs(Flash.Trackers) do
          if tracker and tracker.TaskConfig and table.contains(RuleConf.task_ids, tracker.TaskConfig.id) then
            tracker.Shine = true
          end
        end
      end
    end
  end
  if Action.status == ProtoEnum.MinigameStatus.MS_OPEN then
    Log.Debug("minigame start open")
    self.OpenCamera = true
    self.bHasRewardCreated = false
    self._RecoveryActionCache = nil
    self._RecoveryCacheTime = 0
    _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, true, UE4.EPlayerForceHiddenType.MiniGame)
    _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.SetOnlineTeammateTagVisible, false)
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenOrCloseMainUIDownTips, false, "MiniGameClose")
    if self:CheckShouldHalt() then
      if self.DelayHandle then
        _G.DelayManager:CancelDelayById(self.DelayHandle)
        self.DelayHandle = nil
      end
      self.DelayHandle = DelayManager:DelaySeconds(0.5, function()
        self.DelayHandle = nil
        Log.Warning("\231\173\137\229\190\133\228\184\138\228\184\128\230\172\161\231\154\132\229\176\143\230\184\184\230\136\143\231\187\147\230\157\159\228\184\173~\231\168\141\229\174\137\229\139\191\232\186\129")
        self:OnMinigameNotify(Action, Tag, BaseData)
      end)
      return
    end
    self.Status = ProtoEnum.MinigameStatus.MS_OPEN
    if not self.bRestarting then
      self:StopRide()
    end
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_MINI_GAME)
    if MiniGameConfig then
      if MiniGameConfig.bgm_minigame then
        _G.NRCAudioManager:BatchSetState(string.format("MiniGame;MiniGame;%s", MiniGameConfig.bgm_minigame))
      else
        _G.NRCAudioManager:BatchSetState("MiniGame;MiniGame;MiniGame_Type;MiniGame_Common")
      end
      Log.Debug("==amonsu==MiniGameModule==MS_OPEN==CreateWall", MiniGameConfig.block_id, self.bNightmare)
      _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.CreateWall, MiniGameConfig.block_id, self.bNightmare)
      self:ShowStartBanner(self.bNightmare)
      local MiniGameCameraConfig
      if MiniGameConfig.opening_camera > 0 then
        MiniGameCameraConfig = DataConfigManager:GetCameraMoveLite(MiniGameConfig.opening_camera, true)
      end
      if self.bRestarting then
        self:TeleportPlayerToStart(MiniGameConfig, false)
        self.bRestarting = false
        self:StopRide()
      end
      a.task(function()
        self.bIsInCoroutine = true
        self.HasHalted = false
        local Panel
        Log.Debug("minigame coroutine enter")
        if not self:HasPanel("MiniGamePanel") then
          if not self.NeedPlayNightmareAction then
            self:CloseAllOtherUI()
          end
          if self:CheckShouldHalt() then
            return self:DoHaltCoroutine()
          end
          a.wait(a.wrap(self.OpenPanelCoroutine)(self))
          Panel = self:GetPanel("MiniGamePanel")
          if self:CheckShouldHalt() then
            return self:DoHaltCoroutine()
          end
          self:DispatchEvent(MiniGameModuleEvent.Progression, Action, BaseData.space_time_ms)
        else
          Panel = self:GetPanel("MiniGamePanel")
          Panel:SetMiniGameConfID(self.ConfigId, self.bNightmare)
        end
        if self:CheckShouldHalt() then
          return self:DoHaltCoroutine()
        end
        if MiniGameCameraConfig then
          Panel:SetTitleText(MiniGameCameraConfig.guide_tips)
        else
          Panel:SetTitleText("")
        end
        Panel:OnStart(MiniGameConfig.time_limit and 0 == MiniGameConfig.time_limit)
        _G.NRCAudioManager:SetStateByName("MiniGame_Phase", "MiniGame_Phase1", "MiniGame")
        NRCEventCenter:DispatchEvent(MiniGameModuleEvent.OnTaskClick, -1)
        Panel.TickShowBeam = true
        if not self.NeedPlayNightmareAction then
          _G.NRCAudioManager:PlaySound2DAuto(1220002022, "MiniGameModule show beam")
          self:DisablePlayerControl()
        end
        NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
        Panel:SetRemainTime(MiniGameConfig.time_limit)
        Panel:SetMiniGameArea(MiniGameConfig.gameplay_area)
        Panel:UpdateTimeHint()
        local CameraFadeInTime = DataConfigManager:GetGlobalConfigNumByKeyType("minigame_blackscreen_cut_in", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 500) / 1000
        local BlackFadeInDuration = DataConfigManager:GetGlobalConfigNumByKeyType("minigame_blackscreen_fade_in", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 500) / 1000
        local BlackDuration = DataConfigManager:GetGlobalConfigNumByKeyType("minigame_blackscreen_last", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 1000) / 1000
        local BlackFadeOutDuration = DataConfigManager:GetGlobalConfigNumByKeyType("minigame_blackscreen_fade_out", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 500) / 1000
        if not MiniGameCameraConfig or MiniGameCameraConfig.camera_launch_time / 1000 < 0.5 then
          if not self.NeedPlayNightmareAction then
            self:FadeInBlack(1)
            if MiniGameConfig.miniGame_Tod and 0 ~= MiniGameConfig.miniGame_Tod then
              self:ChangeTimeOfDay()
            end
            if MiniGameConfig.guide_rode and 0 ~= MiniGameConfig.guide_rode then
              self.LoadGuideRoadReq = _G.NRCResourceManager:LoadResAsync(self, GuideRoadClass, -1, 10, self.LoadGuideRoadSuccess, self.LoadGuideRoadFailed)
            end
            a.wait(au.DelaySeconds(2))
          end
          self:TeleportPlayerToStart(MiniGameConfig, false)
          if not self.NeedPlayNightmareAction then
            self:FadeOutBlack(1)
            a.wait(au.DelaySeconds(2))
          end
          if self:CheckShouldHalt() then
            return self:DoHaltCoroutine()
          end
        else
          if MiniGameConfig.miniGame_Tod and 0 ~= MiniGameConfig.miniGame_Tod then
            self:FadeInBlack(2)
            self:ChangeTimeOfDay()
            a.wait(au.DelaySeconds(2))
            self:FadeOutBlack(1)
          end
          if MiniGameConfig.guide_rode and 0 ~= MiniGameConfig.guide_rode then
            self.LoadGuideRoadReq = _G.NRCResourceManager:LoadResAsync(self, GuideRoadClass, -1, 10, self.LoadGuideRoadSuccess, self.LoadGuideRoadFailed)
          end
          NRCModuleManager:DoCmd(CameraModuleCmd.RequestRocoCameraAndInit)
          local DeltaTime = self:StartCamera(MiniGameCameraConfig)
          self.Stage = MiniGameStage.Perform
          a.wait(au.DelaySeconds(math.max(0, DeltaTime + MiniGameCameraConfig.focus_time / 1000 - CameraFadeInTime)))
          if self:CheckShouldHalt() then
            return self:DoHaltCoroutine()
          end
          if not self.NeedPlayNightmareAction then
            self:FadeInBlack(BlackFadeInDuration)
            a.wait(au.DelaySeconds(CameraFadeInTime))
          end
          if self:CheckShouldHalt() then
            return self:DoHaltCoroutine()
          end
          Panel.TickShowBeam = false
          NRCEventCenter:DispatchEvent(MiniGameModuleEvent.OnTaskClick, -1)
          self:TeleportPlayerToStart(MiniGameConfig, false)
          local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
          Player:GetUEController():ReleaseRocoCamera(1)
          self:TeleportPlayerToStart(MiniGameConfig, true)
          a.wait(au.DelaySeconds(BlackDuration))
          UE4.UNRCStatics.BlockTillLevelStreamingCompleted(UE4Helper.GetCurrentWorld())
          if self:CheckShouldHalt() then
            return self:DoHaltCoroutine()
          end
          if not self.NeedPlayNightmareAction then
            self:FadeOutBlack(BlackFadeOutDuration)
            a.wait(au.DelaySeconds(BlackFadeOutDuration))
          end
          if self:CheckShouldHalt() then
            return self:DoHaltCoroutine()
          end
        end
        if MiniGameConfig.time_limit and 0 ~= MiniGameConfig.time_limit then
          _G.NRCAudioManager:PlaySound2DAuto(1220002021, "MiniGameModule countdown")
          a.wait(a.wrap(Panel.PlayAndWaitAnim)(Panel, Panel.Countdown))
          if self:CheckShouldHalt() then
            return self:DoHaltCoroutine()
          end
          a.wait(a.wrap(Panel.PlayAndWaitAnim)(Panel, Panel.Timebar_In))
        end
        if self:CheckShouldHalt() then
          return self:DoHaltCoroutine()
        end
        if not self.NeedPlayNightmareAction then
          NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
          self:EnablePlayerControl()
        end
        self.bIsInCoroutine = false
        self:Initialization()
        _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenOrCloseMainUIDownTips, true, "MiniGameClose")
        self.OpenCamera = false
        _G.NRCAudioManager:SetStateByName("MiniGame_Phase", "MiniGame_Phase2", "MiniGame")
      end)()
    end
  elseif Action.status == ProtoEnum.MinigameStatus.MS_EXIT or Action.status == ProtoEnum.MinigameStatus.MS_TIMEOUT then
    Log.Debug("MS_Exit")
    self.OpenCamera = false
    _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, false, UE4.EPlayerForceHiddenType.MiniGame)
    _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.SetOnlineTeammateTagVisible, true)
    if self:HasPanel("MiniGameModuleLeavePanel") then
      self:ClosePanel("MiniGameModuleLeavePanel")
    end
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
    local HasDialogue = _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.CheckHasDialogue)
    if not HasDialogue then
      NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
    end
    self:EnablePlayerControl()
    local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    Player:GetUEController():ReleaseRocoCamera(0)
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_MINI_GAME)
    if MiniGameConfig then
      Log.Debug("==amonsu==MiniGameModule==MS_EXIT==DestroyWall", MiniGameConfig.block_id, self.bNightmare)
      _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.DestroyWall, MiniGameConfig.block_id, self.bNightmare)
    end
    self.Status = ProtoEnum.MinigameStatus.MS_EXIT
    if self.BigBen and self.BigBen.luaObj then
      local ClockSetting = self.Settings[self.ConfigId] or MiniGameClockSettings:newMiniGameClockSettings()
      ClockSetting.Activate = false
      ClockSetting.Reset = true
      ClockSetting.timeout = false
      self.Settings[self.ConfigId] = ClockSetting
      self.BigBen.luaObj:ApplySettings()
    end
    self.Status = nil
    self:MinigameEndDataReset()
    _G.NRCAudioManager:BatchSetState("MiniGame;None")
    _G.NRCEventCenter:DispatchEvent(MiniGameModuleEvent.End)
    if self:HasPanel("MiniGamePanel") then
      local Panel = self:GetPanel("MiniGamePanel")
      if Panel then
        Panel:StopAllAnimations()
      end
    elseif self:HasPanel("MiniGameModuleNightmarePanel") then
      local Panel = self:GetPanel("MiniGameModuleNightmarePanel")
      if Panel then
        Panel:StopAllAnimations()
        Log.Debug("Has MiniGameModuleNightmarePanel")
      end
    elseif self:CheckShouldHalt() then
      return self:DoHaltCoroutine()
    end
    self:DispatchEvent(MiniGameModuleEvent.Exit)
    self:DispatchEvent(MiniGameModuleEvent.End, true)
    self:StopRide()
    if self.BigBen and self.BigBen.viewObj and self.BigBen.viewObj.RedDarkGreenLight then
      self.BigBen.viewObj:RedDarkGreenLight()
    end
  elseif Action.status == ProtoEnum.MinigameStatus.MS_LEAVE_DUNGEON then
    _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, false, UE4.EPlayerForceHiddenType.MiniGame)
    _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.SetOnlineTeammateTagVisible, true)
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_MINI_GAME)
    if MiniGameConfig then
      Log.Debug("==amonsu==MiniGameModule==MS_LEAVE_DUNGEON==DestroyWall", MiniGameConfig.block_id, self.bNightmare)
      _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.DestroyWall, MiniGameConfig.block_id, self.bNightmare)
    end
    self:Reset()
    self:StopRide()
    self:MinigameEndDataReset()
    _G.NRCAudioManager:BatchSetState("MiniGame;None")
    if self.BigBen and self.BigBen.viewObj and self.BigBen.viewObj.RedDarkGreenLight then
      self.BigBen.viewObj:RedDarkGreenLight()
    end
  elseif Action.status == ProtoEnum.MinigameStatus.MS_FINISH then
    _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, false, UE4.EPlayerForceHiddenType.MiniGame)
    _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.SetOnlineTeammateTagVisible, true)
    if not self.Status then
      self:CreateAwards(Action.minigame_cfg_id)
    else
      local OldStatus = self.Status
      self.Status = ProtoEnum.MinigameStatus.MS_FINISH
      _G.NRCAudioManager:SetStateByName("MiniGame_Phase", "MiniGame_Phase4", "MiniGame")
      if not self.NeedPlayNightmareCleanAction then
        if OldStatus == ProtoEnum.MinigameStatus.MS_FINISH then
          Log.Error("Mini Game already in FINISH State")
          if self.bHasRewardCreated then
          else
            self:CreateAwards(Action.minigame_cfg_id)
          end
        else
          self.bHasRewardCreated = false
          self:OnGameFinished()
        end
      else
        self.NeedFinishGameByCleanAction = true
      end
      if MiniGameConfig then
        Log.Debug("==amonsu==MiniGameModule==MS_FINISH==DestroyWall", MiniGameConfig.block_id, self.bNightmare)
        _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.DestroyWall, MiniGameConfig.block_id, self.bNightmare)
      end
    end
  elseif Action.status == ProtoEnum.MinigameStatus.MS_RECOVERY or Action.status == ProtoEnum.MinigameStatus.MS_PROGRESS then
    self.bHasRewardCreated = false
    local needRecovery = Action.status == ProtoEnum.MinigameStatus.MS_RECOVERY or not self:IsPlaying()
    if needRecovery then
      if self.RecoveryDelayHandle then
        _G.DelayManager:CancelDelayById(self.RecoveryDelayHandle)
        self.RecoveryDelayHandle = nil
      end
      _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, true, UE4.EPlayerForceHiddenType.MiniGame)
      _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.SetOnlineTeammateTagVisible, false)
      _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_MINI_GAME)
      self.Status = ProtoEnum.MinigameStatus.MS_RECOVERY
      self.ConfigId = Action.minigame_cfg_id
      self:StopRide()
      if MiniGameConfig then
        if MiniGameConfig.opening_camera > 0 then
          local MiniGameCameraConfig = DataConfigManager:GetCameraMoveLite(MiniGameConfig.opening_camera, true)
          if MiniGameCameraConfig then
            self._GuideTips = MiniGameCameraConfig.guide_tips
          end
        end
        if MiniGameConfig.guide_rode and 0 ~= MiniGameConfig.guide_rode then
          self.LoadGuideRoadReq = _G.NRCResourceManager:LoadResAsync(self, GuideRoadClass, -1, 10, self.LoadGuideRoadSuccess, self.LoadGuideRoadFailed)
        end
      end
      self._RecoveryActionCache = Action
      self._RecoveryCacheTime = BaseData.space_time_ms
      if not self:HasPanel("MiniGamePanel") then
        self:OpenPanel("MiniGamePanel")
      end
      if not self:HasPanel("MiniGameModuleNightmarePanel") then
        self:OpenPanel("MiniGameModuleNightmarePanel")
      end
      
      function self.LatentRecovery()
        if self.BigBen and self.BigBen.viewObj then
          if self.BigBen.viewObj.RedLightGreenDark then
            self.BigBen.viewObj:RedLightGreenDark()
          end
          local LocSet = self.Settings[self.ConfigId] or MiniGameClockSettings:newMiniGameClockSettings()
          LocSet.Activate = true
          LocSet.Reset = false
          local MiniGameConfer = _G.DataConfigManager:GetMinigameConf(self.ConfigId, true)
          if MiniGameConfer then
            local symbol = (MiniGameConfer.time_limit - self.TimeRemain) / MiniGameConfer.time_limit * 12
            LocSet.StartSymbol = math.floor(symbol)
            LocSet.DurationPer = 9999
            LocSet.PlayRate = 1.0 / (MiniGameConfer.time_limit / 0.33)
            LocSet.StartPos = 0.33 * ((MiniGameConfer.time_limit - self.TimeRemain) / MiniGameConfer.time_limit)
            LocSet.Reset = false
            LocSet.Finish = false
            LocSet.Activate = true
            self.Settings[self.ConfigId] = LocSet
            if self.BigBen.luaObj.ApplySettings then
              self.BigBen.luaObj:ApplySettings()
            end
            self:RecordOwnerClock()
          end
        end
      end
      
      self.Time = UE4Helper.GetTime()
      if self.BigBen and self.BigBen.viewObj then
        self:LatentRecovery()
        self.LatentRecovery = nil
      end
      NRCEventCenter:DispatchEvent(MiniGameModuleEvent.Start, self.bNightmare)
      self:DispatchEvent(MiniGameModuleEvent.Recovery)
      if MiniGameConfig then
        if MiniGameConfig.bgm_minigame then
          _G.NRCAudioManager:BatchSetState(string.format("MiniGame;MiniGame;%s", MiniGameConfig.bgm_minigame))
        else
          _G.NRCAudioManager:BatchSetState("MiniGame;MiniGame;MiniGame_Type;MiniGame_Common")
        end
        _G.NRCAudioManager:SetStateByName("MiniGame_Phase", "MiniGame_Phase2", "MiniGame")
        Log.Debug("==amonsu==MiniGameModule==MS_RECOVERY==CreateWall", MiniGameConfig.block_id, self.bNightmare)
        _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.CreateWall, MiniGameConfig.block_id, self.bNightmare)
      end
      self.RecoveryDelayHandle = _G.DelayManager:DelaySeconds(3, function()
        self.RecoveryDelayHandle = nil
        NRCEventCenter:DispatchEvent(MiniGameModuleEvent.OnTaskClick, -1)
      end)
      self.Stage = MiniGameStage.Running
    end
    if self.Stage == MiniGameStage.Running then
      self:DispatchEvent(MiniGameModuleEvent.tick, true)
    end
  end
  if not self:HasPanel("MiniGamePanel") and not self:HasPanel("MiniGameModuleNightmarePanel") then
    self._ProgressActionCache = Action
  end
  if self.ConfigId ~= Action.minigame_cfg_id then
    Log.Error("MiniGame Config Id Mismatch!")
  end
  self:DispatchEvent(MiniGameModuleEvent.Progression, Action, BaseData.space_time_ms)
end

function MiniGameModule:OnGameFinished()
  local MiniGameConfig = DataConfigManager:GetMinigameConf(self.ConfigId)
  if not MiniGameConfig then
    Log.Error("minigame config not found")
    return
  end
  if self.BigBen and self.BigBen.viewObj and self.BigBen.viewObj.AllDark then
    self.BigBen.viewObj:AllDark()
  end
  local Panel = self:GetPanel("MiniGamePanel")
  a.task(function()
    self:ClosePanel("MiniGameModuleLeavePanel")
    local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.OpenInputBlocker, "MiniGameModule")
    Player.inputComponent:SetCameraControlEnable(self, false)
    Player.inputComponent:SetInputEnable(self, false)
    Player.interactionComponent:SetEnable(false)
    NRCEventCenter:DispatchEvent(MiniGameModuleEvent.StartFinishedCamera, true)
    NRCModuleManager:DoCmd(MainUIModuleCmd.UI_OnSetVitalityHideFlag, true)
    NRCEventCenter:DispatchEvent(MiniGameModuleEvent.OnGameFinishedImmediate)
    self:DispatchEvent(MiniGameModuleEvent.tick, false)
    local MiniGameCameraConfig
    if MiniGameConfig.ending_camera > 0 then
      if not self.bNightmare then
        a.wait(au.DelaySeconds(2))
      end
      self:StopRide()
      Player:SendEvent(PlayerModuleEvent.ON_STOP_PASSIVE_FALLING)
      Player:Stop()
      MiniGameCameraConfig = DataConfigManager:GetCameraMoveLite(MiniGameConfig.ending_camera, true)
      if MiniGameCameraConfig then
        NRCModuleManager:DoCmd(CameraModuleCmd.RequestRocoCameraAndInit)
        local DeltaTime = self:StartCamera(MiniGameCameraConfig)
        a.wait(au.DelaySeconds(DeltaTime or 0))
      end
      a.wait(a.wrap(self.CreateAwards)(self, self.ConfigId))
      if MiniGameCameraConfig then
        a.wait(au.DelaySeconds(MiniGameCameraConfig.focus_time / 1000))
        if MiniGameCameraConfig.focus_end_in_black then
          self:FadeInBlack(1)
          a.wait(au.DelaySeconds(1))
        end
        self:BlendToBigWorldCamera(MiniGameCameraConfig.camera_back_time / 1000 or 0)
        Player:GetUEController():ReleaseRocoCamera(0)
        a.wait(au.DelaySeconds(MiniGameCameraConfig.camera_back_time / 1000 or 0))
      end
      if MiniGameCameraConfig and MiniGameCameraConfig.focus_end_in_black then
        self:FadeOutBlack(1)
        a.wait(au.DelaySeconds(1))
      end
    else
      a.wait(a.wrap(self.CreateAwards)(self, self.ConfigId))
      a.wait(au.DelaySeconds(0.2))
      self:StopRide()
      Player:SendEvent(PlayerModuleEvent.ON_STOP_PASSIVE_FALLING)
      Player:Stop()
    end
    a.wait(au.DelaySeconds(0.5))
    NRCEventCenter:DispatchEvent(MiniGameModuleEvent.StartFinishedCamera, false)
    NRCModuleManager:DoCmd(MainUIModuleCmd.UI_OnSetVitalityHideFlag, false)
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_MINI_GAME)
    self:EnablePlayerControl()
    if Panel then
      Panel:ShowSuccess()
    end
    self:DispatchEvent(MiniGameModuleEvent.End, false)
    NRCEventCenter:DispatchEvent(MiniGameModuleEvent.End)
    _G.NRCAudioManager:BatchSetState("MiniGame;None")
    if self.BigBen and self.BigBen.luaObj then
      local ClockSetting = self.Settings[self.ConfigId] or MiniGameClockSettings:newMiniGameClockSettings()
      ClockSetting.Activate = false
      ClockSetting.Reset = true
      ClockSetting.Finish = true
      ClockSetting.timeout = false
      self.Settings[self.ConfigId] = ClockSetting
      self.BigBen.luaObj:ApplySettings()
    end
    self.Status = nil
    self:MinigameEndDataReset()
  end)()
end

function MiniGameModule:OnGameTimeOut()
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_POPUP)
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_TOP_MSG)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1340, "Lua_NPCMiniGameClock:ApplySettings start ringing")
  local Panel = self:GetPanel("MiniGamePanel")
  if Panel then
    a.task(function()
      if self:HasPanel("MiniGameModuleLeavePanel") then
        local ExitPanel = self:GetPanel("MiniGameModuleLeavePanel")
        if ExitPanel then
          self:ClosePanel("MiniGameModuleLeavePanel")
        end
      end
      if self.BigBen and self.BigBen.luaObj then
        local ClockSetting = self.Settings[self.ConfigId] or MiniGameClockSettings:newMiniGameClockSettings()
        ClockSetting.Activate = false
        ClockSetting.Reset = false
        ClockSetting.Finish = true
        self.Settings[self.ConfigId] = ClockSetting
        self.BigBen.luaObj:ApplySettings()
      end
      NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
      a.wait(a.wrap(Panel.PlayAndWaitAnim)(Panel, Panel.TimeUp))
      NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
      local bGiveUp = true
      local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      if not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH) then
        bGiveUp = a.wait(a.wrap(Panel.PopTimeOutWindow)(Panel))
      end
      if self.BigBen and self.BigBen.luaObj then
        local ClockSetting = self.Settings[self.ConfigId] or MiniGameClockSettings:newMiniGameClockSettings()
        ClockSetting.Activate = false
        ClockSetting.Reset = true
        ClockSetting.Finish = false
        self.Settings[self.ConfigId] = ClockSetting
        self.BigBen.luaObj:ApplySettings()
      end
      if bGiveUp then
        self:DispatchEvent(MiniGameModuleEvent.End, true)
        NRCEventCenter:DispatchEvent(MiniGameModuleEvent.End)
        self:StopRide()
        self.Status = nil
      else
        self:RestartMiniGame()
      end
    end)()
    self:MinigameEndDataReset()
  else
    Log.Error("minigame time out but panel not opened")
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_MINI_GAME)
    self:Reset()
    self:StopRide()
    self:MinigameEndDataReset()
  end
  if self.BigBen and self.BigBen.viewObj and self.BigBen.viewObj.RedDarkGreenLight then
    self.BigBen.viewObj:RedDarkGreenLight()
  end
end

function MiniGameModule:OnActive()
  NRCEventCenter:RegisterEvent("DialogueModule", self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  NRCEventCenter:RegisterEvent("DialogueModule", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisConnected)
  _G.NRCEventCenter:RegisterEvent("DialogueModule", self, SceneEvent.OnPlayerDead, self.OnPlayerDead)
end

function MiniGameModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnPlayerDead, self.OnPlayerDead)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisConnected)
end

function MiniGameModule:ShowFailure()
  if self:HasPanel("MiniGamePanel") then
    local Panel = self:GetPanel("MiniGamePanel")
    Panel:ShowFailure()
  end
end

function MiniGameModule:CloseAllOtherUI()
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_POPUP)
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_TOP)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenPanelLobbyMain)
end

function MiniGameModule:RestartMiniGame()
  if _G.BattleManager.isInBattle then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH) then
    return
  end
  Log.Warning("RestartMiniGame")
  self:CloseAllOtherUI()
  self:DispatchEvent(MiniGameModuleEvent.tick, false)
  local RestartReq = ProtoMessage:newZoneReopenMinigameReq()
  RestartReq.minigame_cfg_id = self.ConfigId
  RestartReq.trigger_obj = not self.OwnerId and self.BigBen and self.BigBen.serverData.base.actor_id
  self.bRestarting = true
  NRCEventCenter:DispatchEvent(MiniGameModuleEvent.End)
  self:DispatchEvent(MiniGameModuleEvent.End, true)
  player:SendEvent(PlayerModuleEvent.ON_STOP_PASSIVE_FALLING)
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_REOPEN_MINIGAME_REQ, RestartReq, self, self.OnRestartRsp)
  local MiniGameConfig = self.ConfigId and DataConfigManager:GetMinigameConf(self.ConfigId)
  if MiniGameConfig then
    self:StopRide()
    self:TeleportPlayerToStart(MiniGameConfig, false)
  end
end

function MiniGameModule:GetState()
  return self.Status
end

function MiniGameModule:OnRestartRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_MINI_GAME)
    if self.Status == ProtoEnum.MinigameStatus.MS_TIMEOUT then
      self:DispatchEvent(MiniGameModuleEvent.End, true)
      NRCEventCenter:DispatchEvent(MiniGameModuleEvent.End)
      self:StopRide()
      self.Status = nil
    end
    Log.Error("MiniGameModule restart game fail")
    return
  end
end

function MiniGameModule:CreateAwards(ConfigId, Callback)
  local AwardReq = _G.ProtoMessage:newZoneSceneRewardMinigameReq()
  AwardReq.minigame_cfg_id = ConfigId or self.ConfigId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_REWARD_MINIGAME_REQ, AwardReq, self, self.OnAwardCreatedRsp)
  if Callback then
    Callback()
  end
end

function MiniGameModule:OnAwardCreatedRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.bHasRewardCreated = true
  end
  if self.CreateAwardCoroutineDone then
    self.CreateAwardCoroutineDone()
  end
end

function MiniGameModule:GetSettings(Id)
  return self.Settings[Id or self.ConfigId]
end

function MiniGameModule:Kill(KillDex)
  if self.Settings[self.ConfigId] then
    self.Settings[self.ConfigId].StartSymbol = math.floor(KillDex)
  end
  local TimeActor = self:TryGetTimeActor()
  if TimeActor then
    TimeActor:Kill(math.floor(KillDex))
  end
end

function MiniGameModule:TryGetTimeActor()
  if not self.BigBen then
    return
  end
  local View = self.BigBen.viewObj
  local Time = View and View.Time
  if not Time then
    return
  end
  return Time:GetChildActor()
end

function MiniGameModule:OnPlayerDead()
  if not self:IsPlaying() then
    return
  end
  if self:HasPanel("MiniGameModuleLeavePanel") then
    self:ClosePanel("MiniGameModuleLeavePanel")
  end
  self:DispatchEvent(MiniGameModuleEvent.tick, false)
end

function MiniGameModule:AreaPosToTransform(AreaConf)
  if AreaConf and AreaConf.pos and #AreaConf.pos > 0 then
    local Location = AreaConf.pos[1].position_xyz
    local Rotation = AreaConf.pos[1].rotation_xyz
    local ResultTransform = UE4.FTransform()
    ResultTransform.Translation = UE4.FVector(Location[1], Location[2], Location[3])
    ResultTransform.Rotation = UE4.FRotator(Rotation[1], Rotation[2], Rotation[3])
    return ResultTransform
  end
end

function MiniGameModule:OpenExitPanel()
  if self.Status == ProtoEnum.MinigameStatus.MS_FINISH then
    return
  end
  self:OpenPanel("MiniGameModuleLeavePanel")
end

function MiniGameModule:OnCameraMotionDone(deltatime)
  self:Initialization()
end

function MiniGameModule:LineCamera(conf, bReverse)
  local AreaConfig = DataConfigManager:GetAreaConf(conf.move_path)
  local TargetCameraLocation = self:AreaPosToTransform(AreaConfig)
  local CameraMotionInfo = NRCModuleManager:DoCmd(CameraModuleCmd.FillCameraMotionInfo, conf.move_type)
  CameraMotionInfo.TargetCameraTransform = TargetCameraLocation
  CameraMotionInfo.InitCameraTransform = self:GetBigWorldCameraTransform()
  if bReverse then
    CameraMotionInfo.CameraMoveTime = conf.camera_back_time / 1000
  else
    CameraMotionInfo.CameraMoveTime = conf.camera_launch_time / 1000
  end
  CameraMotionInfo.NonStoppableByObstacle = true
  CameraMotionInfo.CustomConfig = {
    bReverse = bReverse,
    FocusNpcId = conf.focus_npc
  }
  NRCModuleManager:DoCmd(CameraModuleCmd.StartCameraMotion, CameraMotionInfo)
end

function MiniGameModule:GetBigWorldCameraTransform()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Controller = player:GetUEController()
  local result = UE4.FTransform()
  result.Translation = player:GetActorLocation()
  result.Rotation = Controller.PlayerCameraManager.CameraRotation
  Log.Error(result.Translation, player:GetActorLocation())
  return result
end

function MiniGameModule:PathCamera(conf, bReverse)
  local CameraMotionInfo = NRCModuleManager:DoCmd(CameraModuleCmd.FillCameraMotionInfo, conf.move_type)
  if bReverse then
    CameraMotionInfo.CameraMoveTime = conf.camera_back_time / 1000
  else
    CameraMotionInfo.CameraMoveTime = conf.camera_launch_time / 1000
  end
  CameraMotionInfo.NonStoppableByObstacle = true
  CameraMotionInfo.CustomConfig = {
    AreaId = conf.move_path,
    bReverse = bReverse,
    FocusNpcId = conf.focus_npc
  }
  NRCModuleManager:DoCmd(CameraModuleCmd.StartCameraMotion, CameraMotionInfo)
end

function MiniGameModule:StartCamera(conf, bReverse)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC)
    player.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING)
  end
  if conf.move_type == Enum.NpcInteractCameraMoveType.CAMERA_MOVE_LINE then
    self:LineCamera(conf, bReverse)
  elseif conf.move_type == Enum.NpcInteractCameraMoveType.MINIGAME_DEFAULT_CAMERA then
    self:SimpleCamera(conf, bReverse)
  elseif conf.move_type == Enum.NpcInteractCameraMoveType.CAMERA_MOVE_PATH then
    self:PathCamera(conf, bReverse)
  end
  if bReverse then
    return conf.camera_back_time / 1000
  else
    return conf.camera_launch_time / 1000
  end
end

function MiniGameModule:IsGameLaunchingCamera()
  if self.Status == ProtoEnum.MinigameStatus.MS_FINISH then
    return false
  else
    return true
  end
end

function MiniGameModule:GetMiniGameStage()
  return self.Stage
end

function MiniGameModule:SimpleCamera(conf)
  local confer = _G.DataConfigManager:GetNpcRefreshContentConf(conf.focus_npc[1])
  if not confer or 0 == confer.refresh_param then
    Log.Error("focus npc missing")
    return
  end
  local AreaConf = _G.DataConfigManager:GetAreaConf(confer.refresh_param)
  local pos = AreaConf.pos[1]
  local posReal = UE4.FTransform(UE4.FRotator(0, 0, 0):ToQuat(), UE4.FVector(pos.position_xyz[1], pos.position_xyz[2], pos.position_xyz[3] + conf.height_adjustment), UE4.FVector(1, 1, 1))
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local KamMan = player:GetUEController().playerCameraManager
  local playerCameraManagerPos = KamMan:Abs_GetTransform()
  local distanceToPlayer = playerCameraManagerPos.Translation:Dist(posReal.Translation)
  if not self.MiniGameCamera then
    self.MiniGameCamera = UE4Helper.GetCurrentWorld():Abs_SpawnActor(_G.NRCBigWorldPreloader:Get("CAM_SpringArmActor"), posReal, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    self.MiniGameCameraRef = UnLua.Ref(self.MiniGameCamera)
  else
    self.MiniGameCamera:Abs_K2_SetActorTransform_WithoutHit(posReal)
  end
  local SpringArmComp = self.MiniGameCamera:GetComponentByClass(UE4.URocoSpringArmComponent)
  SpringArmComp:K2_SetWorldRotation(UE4.FRotator(0, pos.rotation_xyz[3] + 180, 0), false, nil, false)
  local CameraComp = self.MiniGameCamera:GetComponentByClass(UE4.UCameraComponent)
  CameraComp.FieldOfView = self:ZoomToFov(conf.zoom / 1000)
  local PlayerKamVec = playerCameraManagerPos.Translation - posReal.Translation
  local NewKamVec = CameraComp:Abs_K2_GetComponentLocation() - posReal.Translation
  PlayerKamVec:Normalize()
  NewKamVec:Normalize()
  SpringArmComp.TargetArmLength = distanceToPlayer
  local deltatime = conf.camera_launch_time / 1000
  player:GetUEController():ChangeToCustomCamera(self.MiniGameCamera, deltatime)
end

function MiniGameModule:FadeInBlack(...)
  local Panel = self:GetPanel("MiniGamePanel")
  if not Panel then
  else
    Panel:FadeInBlack(...)
  end
end

function MiniGameModule:FadeOutBlack(...)
  local Panel = self:GetPanel("MiniGamePanel")
  if not Panel then
  else
    Panel:FadeOutBlack(...)
  end
  NRCEventCenter:DispatchEvent(MiniGameModuleEvent.CountDownToStart, self, self.EnablePlayerControl)
end

function MiniGameModule:EnablePlayerControl()
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  Player.inputComponent:SetCameraControlEnable(self, true)
  Player.inputComponent:SetInputEnable(self, true)
  Player.interactionComponent:SetEnable(true)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.CloseInputBlocker, "MiniGameModule")
end

function MiniGameModule:DisablePlayerControl()
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.OpenInputBlocker, "MiniGameModule")
  Player.inputComponent:SetCameraControlEnable(self, false)
  Player.inputComponent:SetInputEnable(self, false)
  Player.interactionComponent:SetEnable(false)
  Player:Stop()
end

function MiniGameModule:OnOpenMainPanel(arg)
end

function MiniGameModule:OnOpenPanelCallback(panelName, panelIndex, isSucc)
  NRCModuleBase.OnOpenPanelCallback(self, panelName, panelIndex, isSucc)
  if "MiniGamePanel" == panelName and self.MainPanelOpenedCoroutineCallback then
    self.MainPanelOpenedCoroutineCallback()
    self.MainPanelOpenedCoroutineCallback = nil
  end
  if self.LatentRecovery and self.BigBen and self.BigBen.viewObj then
    self:LatentRecovery()
    self.LatentRecovery = false
  end
end

function MiniGameModule:ZoomToFov(zoomer)
  return 3.9018 * zoomer * zoomer - 42.432 * zoomer + 123
end

function MiniGameModule:CheckNightmare()
  local result = false
  if self.ConfigId then
    local MiniGameConfig = DataConfigManager:GetMinigameConf(self.ConfigId, true)
    if MiniGameConfig and (MiniGameConfig.effect_type == Enum.MiniGameType.MINIGAME_NIGHTMARE_SPACE or MiniGameConfig.effect_type == Enum.MiniGameType.MINIGAME_NIGHTMARE_SPACE_SP) then
      result = true
      self.NightmareType = MiniGameConfig.effect_type
    end
  else
    result = false
  end
  self.bNightmare = result
end

function MiniGameModule:MinigameEndDataReset()
  if UE.UObject.IsValid(self.GuideRodeActorRef) then
    UnLua.Unref(self.GuideRodeActorRef)
  end
  if UE.UObject.IsValid(self.GuideRodeActor) then
    self.GuideRodeActor:K2_DestroyActor()
    self.GuideRodeActor = nil
  end
  self.NightmareType = nil
  self.bNightmare = false
  self.NeedPlayNightmareAction = false
  self.bOpenNightmareFinish = false
  self.NeedPlayNightmareCleanAction = false
  self.NeedFinishGameByCleanAction = false
  self._RecoveryActionCache = nil
end

function MiniGameModule:GetStarCount(TriggerID)
  if not TriggerID then
    return 0
  end
  if self.StarCount[TriggerID] then
    return self.StarCount[TriggerID]
  end
  return 0
end

function MiniGameModule:GetAirWallID()
  if self:IsPlaying() then
    local MiniGameConfig = DataConfigManager:GetMinigameConf(self.ConfigId)
    if MiniGameConfig then
      return MiniGameConfig.block_id
    end
  end
end

function MiniGameModule:LoadGuideRoadSuccess(Req, Class)
  local MiniGameConfig = DataConfigManager:GetMinigameConf(self.ConfigId)
  if not MiniGameConfig then
    return
  end
  local SplineConf = DataConfigManager:GetSplineConf(MiniGameConfig.guide_rode)
  if not SplineConf then
    return
  end
  local Pos = UE.FVector(SplineConf.position[1], SplineConf.position[2], SplineConf.position[3])
  local Scale = UE.FVector(SplineConf.scale[1], SplineConf.scale[2], SplineConf.scale[3])
  local Rot = UE.FRotator(SplineConf.rotation[2], SplineConf.rotation[3], SplineConf.rotation[1])
  local Transform = UE.FTransform(Rot:ToQuat(), Pos, Scale)
  self.GuideRodeActor = UE4Helper.GetCurrentWorld():Abs_SpawnActor(Class, Transform, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, nil, nil, nil, MiniGameConfig)
  self.GuideRodeActorRef = UnLua.Ref(self.GuideRodeActor)
end

function MiniGameModule:LoadGuideRoadFailed(Req, Class)
  Log.Error("MiniGameModule:LoadGuideRoadFailed")
end

function MiniGameModule:ChangeTimeOfDay()
  Log.Debug("MiniGameModule ChangeTimeOfDay ", self.ConfigId)
  if not self.ConfigId then
    return
  end
  local MiniGameConfig = DataConfigManager:GetMinigameConf(self.ConfigId)
  if not MiniGameConfig then
    return
  end
  local MiniGameTOD = MiniGameConfig.miniGame_Tod
  if not MiniGameTOD then
    return
  end
  local CurTime = NRCModuleManager:DoCmd(EnvSystemModuleCmd.GetCurrentTime)
  local GameTime
  local TimeArray = TimeOfDay[MiniGameTOD]
  if not TimeArray then
    return
  end
  for i, TimeValue in ipairs(TimeArray) do
    if CurTime > TimeValue.StartTime and CurTime < TimeValue.EndTime then
      Log.Debug("MiniGameModule ChangeTimeOfDay Curtime is", CurTime)
      return
    else
      GameTime = (TimeValue.StartTime + TimeValue.EndTime) * 0.5
    end
  end
  if not GameTime then
    return
  end
  local Req = _G.ProtoMessage:newZoneSceneModGameTimeReq()
  local LocalPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Now = NRCModuleManager:DoCmd(EnvSystemModuleCmd.GetTimestampWithInfo, LocalPlayer.serverData.game_time_infos)
  Now = Now / 1000
  local Today = math.floor(Now / 86400) * 86400
  local DesiredTime = Today + GameTime
  if Now > DesiredTime then
    DesiredTime = DesiredTime + 86400
  end
  Req.time_stamp = math.round(DesiredTime)
  Req.minigame_cfg_id = self.ConfigId
  self.TODSuccess = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_MOD_GAME_TIME_REQ, Req, self, self.OnGameTimeChange)
  Log.Debug("MiniGameModule ChangeTimeOfDay", MiniGameTOD, self.ConfigId, self.TODSuccess)
end

function MiniGameModule:OnGameTimeChange(Req)
end

return MiniGameModule
