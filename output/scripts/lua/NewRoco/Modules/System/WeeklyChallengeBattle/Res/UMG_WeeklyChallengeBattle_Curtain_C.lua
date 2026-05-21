local UMG_WeeklyChallengeBattle_Curtain_C = _G.NRCPanelBase:Extend("UMG_WeeklyChallengeBattle_Curtain_C")
local TIMEOUT_DURATION = 5

function UMG_WeeklyChallengeBattle_Curtain_C:CancelDelay(handleName)
  if self[handleName] then
    _G.DelayManager:CancelDelayById(self[handleName])
    self[handleName] = nil
  end
end

function UMG_WeeklyChallengeBattle_Curtain_C:OnActive(caller, callback)
  Log.Info("UMG_WeeklyChallengeBattle_Curtain_C:OnActive \230\137\147\229\188\128Curtain")
  _G.NRCAudioManager:PlaySound2DAuto(40130001, "UMG_WeeklyChallengeBattle_Curtain_C:OnActive")
  self:StopAllAnimations()
  self:PlayAnimation(self.Close)
  self.caller = caller
  self.callback = callback
  self.bShouldPlayOpen = false
  _G.DelayManager:CancelDelayById(self.closeTimeoutHandle)
  self.closeTimeoutHandle = _G.DelayManager:DelaySeconds(TIMEOUT_DURATION, function()
    self:OnCloseAnimTimeout()
  end)
end

function UMG_WeeklyChallengeBattle_Curtain_C:OnCloseAnimTimeout()
  Log.Warning("UMG_WeeklyChallengeBattle_Curtain_C: Close animation timeout! Force executing callback.")
  self.closeTimeoutHandle = nil
  self:StopAllAnimations()
  if self.callback and self.caller then
    self.callback(self.caller)
  elseif self.callback then
    local callback = self.callback
    callback()
  end
  self.callback = nil
  self.caller = nil
  if self.bShouldPlayOpen then
    self.bShouldPlayOpen = false
    self:PlayAnimation(self.Open)
    _G.DelayManager:CancelDelayById(self.openTimeoutHandle)
    self.openTimeoutHandle = _G.DelayManager:DelaySeconds(TIMEOUT_DURATION, function()
      self:OnOpenAnimTimeout()
    end)
  end
end

function UMG_WeeklyChallengeBattle_Curtain_C:OnDeactive()
  _G.DelayManager:CancelDelayById(self.closeTimeoutHandle)
  _G.DelayManager:CancelDelayById(self.openTimeoutHandle)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
end

function UMG_WeeklyChallengeBattle_Curtain_C:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent("UMG_WeeklyChallengeBattle_Curtain_C", self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
end

function UMG_WeeklyChallengeBattle_Curtain_C:OnConnected()
  Log.Warning("UMG_WeeklyChallengeBattle_Curtain_C:OnConnected \231\189\145\231\187\156\233\135\141\232\191\158\239\188\140\229\188\186\229\136\182\229\133\179\233\151\173\229\185\149\229\184\131")
  self:StopAllAnimations()
  _G.DelayManager:CancelDelayById(self.closeTimeoutHandle)
  _G.DelayManager:CancelDelayById(self.openTimeoutHandle)
  if self.callback and self.caller then
    self.callback(self.caller)
  elseif self.callback then
    local callback = self.callback
    callback()
  end
  self.callback = nil
  self.caller = nil
  self.bShouldPlayOpen = false
  self:DoClose()
end

function UMG_WeeklyChallengeBattle_Curtain_C:TryClose()
  Log.Info("UMG_WeeklyChallengeBattle_Curtain_C:TryClose \229\176\157\232\175\149\229\133\179\233\151\173Curtain")
  if self:IsAnimationPlaying(self.Close) then
    self.bShouldPlayOpen = true
  else
    self:PlayAnimation(self.Open)
    _G.DelayManager:CancelDelayById(self.openTimeoutHandle)
    self.openTimeoutHandle = _G.DelayManager:DelaySeconds(TIMEOUT_DURATION, function()
      self:OnOpenAnimTimeout()
    end)
  end
end

function UMG_WeeklyChallengeBattle_Curtain_C:OnOpenAnimTimeout()
  Log.Warning("UMG_WeeklyChallengeBattle_Curtain_C: Open animation timeout! Force closing panel.")
  self.openTimeoutHandle = nil
  self:StopAllAnimations()
  self:PlayAnimation(self.Open)
end

function UMG_WeeklyChallengeBattle_Curtain_C:OnAnimationFinished(Anim)
  if Anim == self.Close then
    _G.DelayManager:CancelDelayById(self.closeTimeoutHandle)
    if self.callback and self.caller then
      self.callback(self.caller)
    elseif self.callback then
      local callback = self.callback
      callback()
    end
    self.callback = nil
    self.caller = nil
    if self.bShouldPlayOpen then
      self.bShouldPlayOpen = false
      self:PlayAnimation(self.Open)
    end
    _G.DelayManager:CancelDelayById(self.openTimeoutHandle)
    self.openTimeoutHandle = _G.DelayManager:DelaySeconds(TIMEOUT_DURATION, function()
      self:OnOpenAnimTimeout()
    end)
  elseif Anim == self.Open then
    _G.DelayManager:CancelDelayById(self.openTimeoutHandle)
    Log.Info("UMG_WeeklyChallengeBattle_Curtain_C:TryClose \229\133\179\233\151\173Curtain")
    if self.caller and self.caller.OnCurtainCloseComplete then
      self.caller:OnCurtainCloseComplete()
    end
    self:DoClose()
  end
end

return UMG_WeeklyChallengeBattle_Curtain_C
