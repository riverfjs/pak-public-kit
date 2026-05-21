local UMG_Activity_EagleBegins_C = _G.NRCPanelBase:Extend("UMG_Activity_EagleBegins_C")
local TipsModuleEvent = require("NewRoco.Modules.System.TipsModule.TipsModuleEvent")

function UMG_Activity_EagleBegins_C:OnActive(tipObject)
  self.tipObject = tipObject
  local activityId = tipObject.customData and tipObject.customData.activityId
  local activityConf = _G.DataConfigManager:GetActivityConf(activityId)
  self.activityId = activityId
  if not activityConf then
    tipObject:MarkFinished()
    return
  end
  self.bDone = false
  if self.Title1 then
    self.Title1:SetText(activityConf.popup_text)
  end
  local bTipPaused = _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.IsTipPaused)
  if bTipPaused then
    self:OnTipsPaused()
  else
    self:PlayAnimation(self.In)
    if self.activityId then
      _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.MarkActivityCommonOpenTipsPerform, true, self.activityId)
    end
  end
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_EagleBegins_C", self, TipsModuleEvent.Tips_DisplayCoordinatorPaused, self.OnTipsPaused)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_EagleBegins_C", self, TipsModuleEvent.Tips_DisplayCoordinatorResumed, self.OnTipsResumed)
end

function UMG_Activity_EagleBegins_C:OnDeactive()
  if self.tipObject then
    self.tipObject:MarkFinished()
  end
  if not self.bDone then
    Log.Error("UMG_Activity_EagleBegins_C:OnDeactive \229\143\145\231\148\159\228\186\134Tips\230\137\147\229\188\128\228\186\134\228\189\134\230\152\175\229\185\182\230\178\161\230\156\137\229\174\140\230\136\144\232\161\168\231\142\176\231\154\132\230\131\133\229\134\181 activityId = ", self.activityId)
    if self.activityId then
      _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.MarkActivityCommonOpenTipsPerform, false, self.activityId)
      _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.TryShowActivityCommonOpenTips, self.activityId)
    end
  end
end

function UMG_Activity_EagleBegins_C:OnTipsPaused()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_EagleBegins_C:OnTipsResumed()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if not self:IsAnimationPlaying(self.In) and not self.bDone then
    self:PlayAnimation(self.In)
    if self.activityId then
      _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.MarkActivityCommonOpenTipsPerform, true, self.activityId)
    end
  end
end

function UMG_Activity_EagleBegins_C:OnAnimationFinished(anim)
  if anim == self.In then
    self.bDone = true
    if self.tipObject then
      self.tipObject:MarkFinished()
    end
    self:DoClose()
  end
end

function UMG_Activity_EagleBegins_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, TipsModuleEvent.Tips_DisplayCoordinatorPaused, self.OnTipsPaused)
  _G.NRCEventCenter:UnRegisterEvent(self, TipsModuleEvent.Tips_DisplayCoordinatorResumed, self.OnTipsResumed)
end

return UMG_Activity_EagleBegins_C
