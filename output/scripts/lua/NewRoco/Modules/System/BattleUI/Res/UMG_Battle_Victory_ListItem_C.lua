local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local UIUtils = require("NewRoco.Utils.UIUtils")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Battle_Victory_ListItem_C = Base:Extend("UMG_Battle_Victory_ListItem_C")

function UMG_Battle_Victory_ListItem_C:OnConstruct()
end

function UMG_Battle_Victory_ListItem_C:OnAnimationFinished(animation)
  if animation == self.open then
    self:PlayAnimation(self.loop, 0, 0)
  end
end

function UMG_Battle_Victory_ListItem_C:OnDestruct()
  if self.delayId then
    _G.DelayManager:CancelDelay(self.delayId)
    self.delayId = nil
  end
end

function UMG_Battle_Victory_ListItem_C:OnItemUpdate(_data, datalist, index)
  self.NRCImage_Badge:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.data = _data
  self.delayId = _G.DelayManager:DelaySeconds(0.3 * (index - 1), self.ShowIcon, self)
end

function UMG_Battle_Victory_ListItem_C:ShowIcon()
  if self.data then
    local medalLevelInfo = UIUtils.GetMedalLevelInfo(self.data.medal_id, self.data.param)
    if medalLevelInfo then
      self.NRCImage_Badge:SetPath(medalLevelInfo.icon2)
      self.NRCImage_Badge:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  self:PlayAnimation(self.open)
end

function UMG_Battle_Victory_ListItem_C:OnDeactive()
end

return UMG_Battle_Victory_ListItem_C
