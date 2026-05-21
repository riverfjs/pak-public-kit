local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local RoleHpData = require("NewRoco.Modules.System.BattleUI.Res.RoleHP.RoleHPMinItem_Data")
local UMG_RoleHPMinItem_C = Base:Extend("UMG_RoleHPMinItem_C")

function UMG_RoleHPMinItem_C:OnDestruct()
  self:CancelDelay()
end

function UMG_RoleHPMinItem_C:HideAll()
  self.CanvasPanelEnemy:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.CanvasPanelTeam:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.NRCImagehp_team:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.NRCImagehp_enemy:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_RoleHPMinItem_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  Log.Dump(self.uiData, 2, "UMG_RoleHPMinItem_C:OnItemUpdate")
  self:updateItemInfo()
end

function UMG_RoleHPMinItem_C:updateItemInfo()
  self:HideAll()
  self.CanvasPanelEnemy:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.CanvasPanelTeam:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.CanvasPanelNightmare:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.CanvasPanelBlackLock_in:SetVisibility(UE4.ESlateVisibility.Hidden)
  if self.uiData.teamFlag == BattleEnum.Team.ENUM_TEAM then
    self.CanvasPanelEnemy:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.CanvasPanelTeam:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.uiData.isFull then
      self.NRCImagehp_team:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  elseif self.uiData.teamFlag == BattleEnum.Team.ENUM_ENEMY then
    self.CanvasPanelTeam:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.CanvasPanelEnemy:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.uiData.isFull then
      self.NRCImagehp_enemy:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  if self.uiData.isLock == true then
    self:StopAllAnimations()
    self:CancelDelay()
    self:PlayAnimation(self.DelayLockIn)
  elseif true == self.uiData.isShine then
    self:StopAllAnimations()
    self:PlayAnimation(self.shine)
  elseif true == self.uiData.isGrey then
    self:StopAllAnimations()
    self:PlayAnimation(self.gray)
  elseif true == self.uiData.isShow then
    self:StopAllAnimations()
    self:PlayAnimation(self.open)
  elseif true == self.uiData.isOut then
    self:StopAllAnimations()
    self:PlayAnimation(self.Out)
  end
end

function UMG_RoleHPMinItem_C:DelayShowAnim()
  if not self or not UE.UObject.IsValid(self) then
    return
  end
  self.delayShowAnimId = nil
  if not UE.UObject.IsValid(self.CanvasPanelNightmare) or not UE.UObject.IsValid(self.CanvasPanelBlackLock_in) then
    return
  end
  self.CanvasPanelNightmare:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.CanvasPanelBlackLock_in:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.Lock_In)
end

function UMG_RoleHPMinItem_C:CancelDelay()
  if self.delayShowAnimId then
    self:CancelDelay(self.delayShowAnimId)
  end
  self.delayShowAnimId = nil
end

function UMG_RoleHPMinItem_C:OnAnimationFinished(Animation)
  if Animation == self.Lock_In then
    self:PlayAnimation(self.Lock_Loop)
  elseif Animation == self.Lock_Loop then
    self:PlayAnimation(self.Lock_Loop)
  elseif Animation == self.DelayLockIn then
    self:DelayShowAnim()
  end
end

return UMG_RoleHPMinItem_C
