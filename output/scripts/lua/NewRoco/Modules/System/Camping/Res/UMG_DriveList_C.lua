local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_DriveList_C = Base:Extend("UMG_DriveList_C")

function UMG_DriveList_C:OnConstruct()
  self.UpdateHandler = nil
end

function UMG_DriveList_C:OnDestruct()
  if self.UpdateHandler then
    _G.DelayManager:CancelDelayById(self.UpdateHandler)
  end
  self.UpdateHandler = nil
end

function UMG_DriveList_C:OnItemUpdate(_data, datalist, index)
  if _data.heartType == _G.CampingModuleEnum.RoleHpType.GreenHeart then
    self:StopAllAnimations()
    self:PlayAnimation(self.normal)
  elseif _data.heartType == _G.CampingModuleEnum.RoleHpType.GreyHeart then
    self:StopAllAnimations()
    self:PlayAnimation(self.empty)
  elseif _data.heartType == _G.CampingModuleEnum.RoleHpType.HealthHeart then
    self:StopAllAnimations()
    self:PlayAnimation(self.health)
  else
    if _data.heartType == _G.CampingModuleEnum.RoleHpType.GetNewHeart then
      if _data.delayTime > 0 then
        self:PlayAnimation(self.empty)
      end
      self.UpdateHandler = _G.DelayManager:DelaySeconds(_data.delayTime, function()
        self.UpdateHandler = nil
        self:SetVisibility(UE4.ESlateVisibility.Visible)
        self:StopAllAnimations()
        self:PlayAnimation(self.get)
      end)
    else
    end
  end
end

function UMG_DriveList_C:OnItemSelected(_bSelected)
end

function UMG_DriveList_C:OnDeactive()
end

function UMG_DriveList_C:OnActive()
end

return UMG_DriveList_C
