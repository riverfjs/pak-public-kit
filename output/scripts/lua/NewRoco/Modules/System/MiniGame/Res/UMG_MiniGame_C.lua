local MiniGameModuleEvent = reload("NewRoco.Modules.System.MiniGame.MiniGameModuleEvent")
local UMG_MiniGame_C = _G.NRCPanelBase:Extend("UMG_MiniGame_C")

function UMG_MiniGame_C:OnActive()
  self.Visible = false
  self.tick = false
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Module = NRCModuleManager:GetModule("MiniGameModule")
  self.Module:RegisterEvent(self, MiniGameModuleEvent.Progression, self.Progress)
  self.Module:RegisterEvent(self, MiniGameModuleEvent.End, self.OnEnd)
  self.Module:RegisterEvent(self, MiniGameModuleEvent.Exit, self.OnClose)
  self.Module:RegisterEvent(self, MiniGameModuleEvent.Recovery, self.OnRecovery)
  self.Module:RegisterEvent(self, MiniGameModuleEvent.Start, self.OnStart)
  self.Module:RegisterEvent(self, MiniGameModuleEvent.tick, self.SetTick)
  self.TimeRemaining = 0
  self.LastSecond = 0
  self.TipsInterval = 2
  self.CurTipsTime = 0
  self.TipsFadeTime = _G.DataConfigManager:GetGlobalConfigByKey("minigame_area_tips_fade_in_out").num / 1000
  self.TipsLast = _G.DataConfigManager:GetGlobalConfigByKey("minigame_area_tips_last").num / 1000 or 1
  local TimeOutHintConf = _G.DataConfigManager:GetLocalizationConf("Minigame_Finish_Select")
  self.TimeOutHint = TimeOutHintConf and TimeOutHintConf.msg or ""
  self:ShowTimer(false)
  _G.NRCEventCenter:RegisterEvent("MiniGameModule", self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  if self.Module._RecoveryActionCache then
    if self.Module then
      self.bNightmare = self.Module.bNightmare
    end
    self:SetMiniGameConfID(self.Module._RecoveryActionCache.minigame_cfg_id, self.bNightmare)
    self:SetTitleText(self.Module._GuideTips)
    self:OnStart(true)
    self:SetTick(true)
    self:OnRecovery()
    self.Module:DispatchEvent(MiniGameModuleEvent.Progression, self.Module._RecoveryActionCache, self.Module._RecoveryCacheTime)
    self:UpdateTime(math.max(self.Module._RecoveryActionCache.remain_time + self.Module._RecoveryCacheTime / 1000 - _G.ZoneServer:GetServerTime() / 1000, 0), self.MaxTime)
    self.Module._RecoveryActionCache = nil
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").MINIGAME
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
end

function UMG_MiniGame_C:OnEnable()
  if not self.Visible then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MiniGame_C:OnDeactive()
  if self.Module then
    self.Module:UnRegisterEvent(self, MiniGameModuleEvent.Progression)
    self.Module:UnRegisterEvent(self, MiniGameModuleEvent.End)
    self.Module:UnRegisterEvent(self, MiniGameModuleEvent.Exit)
    self.Module:UnRegisterEvent(self, MiniGameModuleEvent.Recovery)
    self.Module:UnRegisterEvent(self, MiniGameModuleEvent.tick)
    self.Module:UnRegisterEvent(self, MiniGameModuleEvent.Start)
  end
  NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  if self.DelayEndId then
    _G.DelayManager:CancelDelayById(self.DelayEndId)
    self.DelayEndId = nil
  end
  if self.CoroutineCallback then
    if self.WaitingForPopWindow then
      self.WaitingForPopWindow = false
      self:YieldCoroutine(true)
    else
      self:YieldCoroutine()
    end
  end
end

function UMG_MiniGame_C:OnConnected(errorCode)
  if 0 == errorCode and self.CoroutineCallback and self.WaitingForPopWindow then
    self.WaitingForPopWindow = false
    self:YieldCoroutine(true)
  end
end

function UMG_MiniGame_C:SetTick(ticker)
  if not ticker or not self.tick then
    self:UpdateTime(self.TimeRemaining, self.MaxTime)
  end
  self.tick = ticker
end

function UMG_MiniGame_C:PopTimeOutWindow(callback)
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  Context:SetTitle(LuaText.umg_minigame_1):SetContent(self.TimeOutHint):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.OnRestartPopWindowDialogueResult):SetCloseOnCancel(true):SetCloseOnOK(true):SetButtonText(LuaText.umg_minigame_2, LuaText.umg_minigame_3):SetCountdown(DialogContext.Mode.OK, 10)
  local isDoOpen = _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  self.WaitingForPopWindow = true
  self.CoroutineCallback = callback
  if not isDoOpen then
    self:OnRestartPopWindowDialogueResult(true)
  end
  return true
end

function UMG_MiniGame_C:PlayAndWaitAnim(Animation, callback)
  self.CoroutineCallback = callback
  if Animation then
    self:YieldCoroutineOnAnimationFinish(Animation)
    self:PlayAnimation(Animation)
  else
    Log.Error("InAnimation is nil")
    self:YieldCoroutine()
  end
end

function UMG_MiniGame_C:YieldCoroutineOnAnimationFinish(Animation)
  self._CoroutineWaitingAnimation = Animation
end

function UMG_MiniGame_C:OnRestartPopWindowDialogueResult(Result)
  self.WaitingForPopWindow = nil
  if self and self.Module then
    self.Module:CloseAllOtherUI()
  else
    Log.Debug("UMG_MiniGame_C:OnRestartPopWindowDialogueResult, self or self.Module is already release")
  end
  self:YieldCoroutine(Result)
end

function UMG_MiniGame_C:SetMiniGameArea(InConfId)
  self.MiniGameAreaConfigId = InConfId
end

function UMG_MiniGame_C:SetMiniGameConfID(InConfId, bNightmare)
  self.MiniGameConfigId = InConfId
  self.bNightmare = bNightmare
end

function UMG_MiniGame_C:YieldCoroutine(...)
  if not self.CoroutineCallback then
    return
  end
  local Callback = self.CoroutineCallback
  self.CoroutineCallback = nil
  Callback(...)
end

function UMG_MiniGame_C:SetActive(InActivate)
  self.bActive = InActivate
end

function UMG_MiniGame_C:OnStart(bBlockAnim)
  if self.tick then
    return
  end
  self.bEnterLastSound = false
  if self.DelayEndId then
    DelayManager:CancelDelayById(self.DelayEndId)
    self.DelayEndId = nil
  end
  self:ShowTimer(false)
  self.bActive = true
  self.TargetBlackAlpha = 0
  self.CurrentBlackAlpha = 0
  self.Visible = true
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  if not bBlockAnim then
    self:StopAnimation(self.fail)
    self:PlayAnimation(self.open)
    self:UpdateTime(self.MaxTime, self.MaxTime)
  else
    self:PlayAnimation(self.open, 0, 1, UE4.EUMGSequencePlayMode.Forward, 99999, false)
  end
  self.PlayerIsInArea = true
  self.MiniGameAreaConfigId = nil
  self.RegionInited = false
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1335, "UMG_MiniGame_C:OnStart")
end

function UMG_MiniGame_C:SetTitleText(InText)
  self.Title:SetText(InText)
end

function UMG_MiniGame_C:ShowTimer(bTurnOn)
  if bTurnOn then
    self.Bg_4:SetRenderOpacity(1)
    self.Time_1:SetRenderOpacity(1)
    self.TimeIcon_1:SetRenderOpacity(1)
  else
    self.Bg_4:SetRenderOpacity(0)
    self.Time_1:SetRenderOpacity(0)
    self.TimeIcon_1:SetRenderOpacity(0)
  end
end

function UMG_MiniGame_C:OnRecovery()
  local MiniGameConfig = DataConfigManager:GetMinigameConf(self.MiniGameConfigId, true)
  local bShowTimer = MiniGameConfig and MiniGameConfig.time_limit and 0 ~= MiniGameConfig.time_limit
  self:ShowTimer(bShowTimer)
  self.Visible = true
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_MiniGame_C:OnEnd(fail)
  self.tick = false
  self.PlayerIsInArea = true
  if self.DelayEndId then
    DelayManager:CancelDelayById(self.DelayEndId)
    self.DelayEndId = nil
  end
  self.DelayEndId = DelayManager:DelaySeconds(5, function()
    Log.Error("\229\176\143\230\184\184\230\136\143ui\229\133\179\233\151\173\229\164\177\232\180\165\239\188\140\229\143\175\232\131\189\230\152\175\229\138\168\230\149\136\229\141\161\228\189\143\228\186\134\239\188\140\229\188\186\229\136\182\229\133\179\233\151\173\228\184\173")
    if self.Module then
      self.Module:ClosePanel("MiniGamePanel")
    end
  end)
  if fail then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1043, "UMG_MiniGame_C:OnEnd fail")
    self:ShowTimer(false)
    self:StopAnimation(self.open)
    if not self.module.bRestarting then
      self:PlayAnimation(self.fail)
    end
  elseif self.bNightmare then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1040, "UMG_MiniGame_C:OnEnd win")
    self:ShowTimer(false)
  else
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1040, "UMG_MiniGame_C:OnEnd win")
    self:StopAnimation(self.open)
    self:ShowTimer(false)
    self:PlayAnimation(self.completed)
  end
end

function UMG_MiniGame_C:OnClose()
  self.bActive = false
  self.tick = false
end

function UMG_MiniGame_C:OnAnimationFinished(anim)
  if self._CoroutineWaitingAnimation == anim then
    self:YieldCoroutine()
  end
  if (anim == self.close or anim == self.fail) and self.DelayEndId then
    DelayManager:CancelDelayById(self.DelayEndId)
    self.DelayEndId = nil
    self.Module:ClosePanel("MiniGamePanel")
  end
end

function UMG_MiniGame_C:OnAddEventListener()
end

function UMG_MiniGame_C:UpdateTime(TimeRemaining, MaxTime)
  if not MaxTime and not self.MaxTime then
    return
  end
  self.MaxTime = MaxTime
  self.StartTime = self:GetSystemTime() - self.MaxTime + TimeRemaining
  self.TimeRemaining = TimeRemaining
end

function UMG_MiniGame_C:Progress(MiniGameProgress, SvrTimeStamp)
  Log.Debug("UMG_MiniGame_C:Progress", MiniGameProgress.remain_time)
  local MiniGameConfer = DataConfigManager:GetMinigameConf(MiniGameProgress.minigame_cfg_id, true)
  if self.Module then
    self.bNightmare = self.Module.bNightmare
  end
  self:SetMiniGameConfID(MiniGameProgress.minigame_cfg_id, self.bNightmare)
  self:UpdateTime(math.max(MiniGameProgress.remain_time + SvrTimeStamp / 1000 - _G.ZoneServer:GetServerTime() / 1000, 0), MiniGameConfer.time_limit)
  self:SetMiniGameArea(MiniGameConfer.gameplay_area)
end

function UMG_MiniGame_C:SetMaxTime(InMaxTime)
  self.MaxTime = InMaxTime
end

function UMG_MiniGame_C:SetRemainTime(InRemainTime)
  self.TimeRemaining = InRemainTime
end

function UMG_MiniGame_C:ShowSuccess()
end

function UMG_MiniGame_C:ShowFailure()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1043, "UMG_MiniGame_C:OnEnd fail")
  self:PlayAnimation(self.fail)
end

function UMG_MiniGame_C:ShowTimeOut()
end

function UMG_MiniGame_C:ShowClear()
end

function UMG_MiniGame_C:GetSystemTime()
  return UE4.UNRCStatics.GetTimestampMicroseconds() / 1000000
end

function UMG_MiniGame_C:OnTick(deltaTime)
  if self.TickShowBeam then
    NRCEventCenter:DispatchEvent(MiniGameModuleEvent.OnTaskClick, 1, true)
  end
  if self.bActive then
    self:UpdateBlack(deltaTime)
  end
  if self.Visible and self.tick then
    if self.MiniGameAreaConfigId then
      if self.CurTipsTime and self.CurTipsTime > 0 then
        self.CurTipsTime = self.CurTipsTime - deltaTime
      else
        self.CurTipsTime = self.TipsInterval
        if not self.PlayerIsInArea and not _G.BattleManager.isInBattle then
          NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_minigame_4, 0)
        end
      end
      local Region = self.Module.MapRegionAreaUtil:GetMapArea(self.MiniGameAreaConfigId)
      if Region and not self.RegionInited and UE.UObject.IsValid(Region._inRegion) then
        Region._inRegion:BuildGrids(UE4.FVector2D(100, 100), false)
        self.RegionInited = true
      end
      local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      if Player and Region then
        self.PlayerIsInArea = Region:InnerContainsPoint(Player:GetActorLocation())
        self.Module.PlayerIsInArea = self.PlayerIsInArea
      end
    end
    local TimePast = self:GetSystemTime() - self.StartTime
    self.TimeRemaining = math.max(0, self.MaxTime - TimePast)
    self.Module.TimeRemain = self.TimeRemaining
    if 0 ~= self.MaxTime then
      self.Module:Kill(12 * ((self.MaxTime - self.TimeRemaining) / self.MaxTime))
    end
    self:UpdateTimeHint()
  end
end

function UMG_MiniGame_C:UpdateTimeHint()
  local Minutes = self.TimeRemaining / 60
  local Seconds = self.TimeRemaining % 60
  self.Time_1:SetText(string.format("%02d:%02d", math.floor(Minutes), math.floor(Seconds)))
  if 0 == math.floor(Minutes) and math.floor(Seconds) <= 10 then
    if self.LastSecond ~= math.floor(Seconds) then
      self:PlayAnimation(self.ComingToAnEnd)
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1339, "UMG_MiniGame_C:OnTick CountDown")
      self.LastSecond = math.floor(Seconds)
    end
    if not self.bEnterLastSound then
      _G.NRCAudioManager:SetStateByName("MiniGame_Phase", "MiniGame_Phase3", "MiniGame")
      self.bEnterLastSound = true
    end
  end
end

function UMG_MiniGame_C:FadeInBlack(Duration)
  Duration = Duration or 0.5
  self.TargetBlackAlpha = 1
  self.FadeSpeed = 2 / Duration
end

function UMG_MiniGame_C:FadeOutBlack(Duration)
  Duration = Duration or 0.5
  self.TargetBlackAlpha = 0
  self.FadeSpeed = 2 / Duration
end

function UMG_MiniGame_C:OnLogin()
end

function UMG_MiniGame_C:OnConstruct()
end

function UMG_MiniGame_C:OnDestruct()
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenOrCloseMainUIDownTips, true, "MiniGameClose")
end

function UMG_MiniGame_C:OnSwitcherState(SwitcherIndex)
  self.State:SetActiveWidgetIndex(SwitcherIndex)
end

return UMG_MiniGame_C
