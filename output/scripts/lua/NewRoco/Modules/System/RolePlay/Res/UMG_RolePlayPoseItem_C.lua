local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_RolePlayPoseItem_C = Base:Extend("UMG_RolePlayPoseItem_C")

function UMG_RolePlayPoseItem_C:OnConstruct()
end

function UMG_RolePlayPoseItem_C:OnDestruct()
end

function UMG_RolePlayPoseItem_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.selectable = not self.data.customData or not self.data.customData.bLocked
  self:UpdateBehaviorConfItem()
end

function UMG_RolePlayPoseItem_C:PlayOutAnimation()
  if self.Selected_out ~= self.FinishedAnimation and not self:IsAnimationPlaying(self.Selected_out) then
    self:PlayAnimation(self.Selected_out)
  end
end

function UMG_RolePlayPoseItem_C:PlayInAnimation()
  if self.Selected_in ~= self.FinishedAnimation and not self:IsAnimationPlaying(self.Selected_in) then
    self:PlayAnimation(self.Selected_in)
  end
end

function UMG_RolePlayPoseItem_C:OnItemSelected(_bSelected)
  if self.data.customData and self.data.customData.bLocked then
    return
  end
  Log.Debug("RolePlayItem PlayAnimation UMG_RolePlayPoseItem_C OnItemSelected", _bSelected, self.FinishedAnimation and self.FinishedAnimation:GetName())
  self:StopAllAnimations()
  if _bSelected then
    self:PlayInAnimation()
  else
    self:PlayOutAnimation()
  end
end

function UMG_RolePlayPoseItem_C:OnAnimationStarted(Animation)
  Log.Debug("RolePlayItem PlayAnimation UMG_RolePlayPoseItem_C Start", Animation:GetName())
end

function UMG_RolePlayPoseItem_C:OnAnimationFinished(Animation)
  Log.Debug("UMG_RolePlayPoseItem_C:OnAnimationFinished", Animation:GetName())
  self.FinishedAnimation = Animation
end

function UMG_RolePlayPoseItem_C:UpdateBehaviorConfItem()
  local conf = _G.DataConfigManager:GetRoleplayBehaviorConf(self.data and self.data.value or 0)
  if conf then
    self.Action:SetPath(conf.icon_path)
    self.Action_Mask:SetPath(conf.icon_path)
    local bLocked = self.data.customData and self.data.customData.bLocked
    if bLocked then
      self.IconMask:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.Lock:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
      self.IconMask:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.Lock:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    local star = self.data.star
    if not star then
      self.StarRating1:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.StarRating2:SetVisibility(UE.ESlateVisibility.Collapsed)
    elseif 1 == star then
      self.StarRating1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.StarRating2:SetVisibility(UE.ESlateVisibility.Collapsed)
    elseif 2 == star then
      self.StarRating1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.StarRating2:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  self.PCKey:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function UMG_RolePlayPoseItem_C:OnDeactive()
end

return UMG_RolePlayPoseItem_C
