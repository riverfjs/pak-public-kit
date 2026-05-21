local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_ElfCollection_Item_C = Base:Extend("UMG_Activity_ElfCollection_Item_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_Activity_ElfCollection_Item_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_Activity_ElfCollection_Item_C:OnDestruct()
  _G.UpdateManager:UnRegister(self)
  if self.DelayId then
    DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
end

function UMG_Activity_ElfCollection_Item_C:OnAddEventListener()
  self:AddButtonListener(self.HabitatBtn.btnLevelUp, self.OnPetInfoBtnClick)
  self:AddButtonListener(self.ThreadBtn.btnLevelUp, self.OnPetInfoBtnClick)
end

function UMG_Activity_ElfCollection_Item_C:OnItemUpdate(_data, datalist, index)
  self.Data = _data
  self.Index = index
  self.PetBaseId = _data.petbase_id
  self.TrailType = _data.trail_type
  self.TrailParam = _data.trail_param
  self.TrailParam2 = _data.trail_param2
  self.Img = _data.img
  self.IsCollected = _data.isCollected
  self.ActivityId = _data.activityId
  self.PetBaseConf = _G.DataConfigManager:GetPetbaseConf(self.PetBaseId)
  self:ShowPetIcon()
  self:ShowCollectBg()
  self:ShowPetInfoBtn()
end

function UMG_Activity_ElfCollection_Item_C:OnItemSelected(_bSelected)
end

function UMG_Activity_ElfCollection_Item_C:ShowPetIcon()
  if not string.IsNilOrEmpty(self.Img) then
    self.PetIcon:SetPath(self.Img)
  end
end

function UMG_Activity_ElfCollection_Item_C:ShowCollectBg()
  if self.IsCollected then
    self.Switcher_BG:SetActiveWidgetIndex(1)
  else
    self.Switcher_BG:SetActiveWidgetIndex(0)
  end
end

function UMG_Activity_ElfCollection_Item_C:ShowPetInfoBtn()
  if self.TrailType == _G.Enum.ActivityTrailTipType.ATTT_NONE then
    self.NRCSwitcher_Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif self.TrailType == _G.Enum.ActivityTrailTipType.ATTT_MAP then
    self.NRCSwitcher_Btn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCSwitcher_Btn:SetActiveWidgetIndex(0)
  elseif self.TrailType == _G.Enum.ActivityTrailTipType.ATTT_TIPS then
    self.NRCSwitcher_Btn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCSwitcher_Btn:SetActiveWidgetIndex(1)
  end
end

function UMG_Activity_ElfCollection_Item_C:OnPetInfoBtnClick()
  if self.ActivityId and _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.CheckActivityExpired, self.ActivityId) then
    ActivityUtils.ShowActivityExpiredTips()
    return
  end
  self:PlayAnimation(self.Click)
  if self.TrailType == _G.Enum.ActivityTrailTipType.ATTT_MAP then
    _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_Activity_ElfCollection_Item_C:OnPetInfoBtnClick")
    ActivityUtils.RequestTracePet(self.TrailParam2, self:GetParentCustomData())
  elseif self.TrailType == _G.Enum.ActivityTrailTipType.ATTT_TIPS then
    _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Activity_ElfCollection_Item_C:OnPetInfoBtnClick")
    _G.NRCModuleManager:DoCmd(ActivityModuleCmd.OpenActivityElfCollectionTips, self.PetBaseId, self.TrailParam)
  end
end

function UMG_Activity_ElfCollection_Item_C:PlayInAnim()
  self.DelayId = _G.DelayManager:DelaySeconds(0.05 * (self.Index - 1), function()
    self:PlayAnimation(self.In)
  end)
end

function UMG_Activity_ElfCollection_Item_C:UpdateIsCollected()
  self.IsCollected = true
  self:ShowCollectBg()
end

return UMG_Activity_ElfCollection_Item_C
