local UMG_BossTips_C = _G.NRCPanelBase:Extend("UMG_BossTips_C")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")

function UMG_BossTips_C:OnConstruct()
  self.tipsDisplayController = _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.GetDisplayController, TipEnum.TipObjectType.LeaderFight)
end

function UMG_BossTips_C:OnActive()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.tipsDisplayController then
    self.tipsDisplayController:BindView(self)
    self.tipsDisplayController:GetExecutor():StartTipDispatchStateListener()
  end
end

function UMG_BossTips_C:OnDestruct()
  if self.tipsDisplayController then
    self.tipsDisplayController:UnBindView()
    self.tipsDisplayController = nil
  end
end

function UMG_BossTips_C:OnAnimationFinished(Animation)
  if self.Anim == Animation and self.tipsDisplayController then
    self.tipsDisplayController:GetExecutor():ConsumeNextTip()
  end
end

function UMG_BossTips_C:OnPlayTips(tip)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.Anim)
end

function UMG_BossTips_C:OnPlayTipStatusChange(pause)
  if pause then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_BossTips_C:OnAllTipsFinished()
  self:DoClose()
end

return UMG_BossTips_C
