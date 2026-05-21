local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local UMG_Curtain_C = _G.NRCPanelBase:Extend("UMG_Curtain_C")
local WeeklyChallengeBattleModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")

function UMG_Curtain_C:OnActive(Caller, CallBack)
  _G.NRCAudioManager:PlaySound2DAuto(40130001, "UMG_Curtain_C:OnActive")
  self.Caller = Caller
  self.CallBack = CallBack
  self:PlayAnimation(self.Close)
  self:OnAddEventListener()
end

function UMG_Curtain_C:TryClose()
  if not self:IsVisible() then
    self:DoClose()
  end
  if self:IsAnimationPlaying(self.Open) then
    return
  end
  if self:IsAnimationPlaying(self.Close) then
    self:DoBack()
    self:StopAnimation(self.Close)
  end
  self:PlayAnimation(self.Open)
end

function UMG_Curtain_C:DoBack()
  _G.NRCEventCenter:DispatchEvent(WeeklyChallengeBattleModuleEvent.OpenLoadingCurtainEvent)
  if self.Caller and self.CallBack then
    self.CallBack(self.Caller)
  elseif self.CallBack then
    self.CallBack()
  end
  self.Caller = nil
  self.CallBack = nil
end

function UMG_Curtain_C:OnAnimationFinished(anim)
  if anim == self.Open then
    self:DoClose()
  elseif anim == self.Close then
    self:DoBack()
  end
end

function UMG_Curtain_C:OnDeactive()
  self:OnRemoveEventListener()
end

function UMG_Curtain_C:OnAddEventListener()
  _G.BattleEventCenter:Bind(self, BattleEvent.EntryHudSkillStartPlayerEvent)
  _G.NRCEventCenter:RegisterEvent("UMG_Curtain_C", self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
end

function UMG_Curtain_C:OnRemoveEventListener()
  _G.BattleEventCenter:UnBind(self)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
end

function UMG_Curtain_C:OnConnected()
  self:DoClose()
end

function UMG_Curtain_C:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.EntryHudSkillStartPlayerEvent then
    self:TryClose()
  end
end

return UMG_Curtain_C
