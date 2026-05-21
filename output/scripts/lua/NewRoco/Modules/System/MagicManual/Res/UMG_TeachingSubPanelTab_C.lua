local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local ModuleData = require("NewRoco/Modules/System/MagicManual/MagicManualModuleData")
local MagicManualModuleEvent = require("NewRoco.Modules.System.MagicManual.MagicManualModuleEvent")
local UMG_TeachingSubPanelTab_C = Base:Extend("UMG_TeachingSubPanelTab_C")

function UMG_TeachingSubPanelTab_C:OnConstruct()
end

function UMG_TeachingSubPanelTab_C:OnDestruct()
end

function UMG_TeachingSubPanelTab_C:OnRefreshData()
  self.data = _G.NRCModuleManager:GetModule("MagicManualModule"):GetBattleTeachInfoById(self.type, self.data.id)
end

function UMG_TeachingSubPanelTab_C:OnItemUpdate(_data, datalist, index)
  self.data = _data.data
  self.conf = self.data and self.data.conf
  self.type = _data.type
  self:OnRefreshData()
  self:StopAllAnimations()
  if _data.type == ModuleData.TeachType.Restraint and self.conf then
    self.IconView:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Title:SetText(self.conf.type_display_name)
    self.Icon:SetPath(self.conf.type_icon_resource)
    self.IconLock:SetPath(self.conf.type_icon_resource)
    if self.data and self.data.is_unlock then
      self:PlayAnimation(self.Unselect_1, self.Unselect_1:GetEndTime())
      self.IconLock:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self:PlayAnimation(self.Unselect_2, self.Unselect_2:GetEndTime())
      self.IconLock:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    self.RedPoint:SetupKey(436, self.data.id)
    self.RedPoint_1:SetupKey(456, {
      Enum.TeachingType.TT_TYPE_ADVANTAGE,
      self.data.id
    })
  elseif _data.type == ModuleData.TeachType.Battle and self.conf then
    if self.data and self.data.is_unlock then
      self:PlayAnimation(self.Unselect_1, self.Unselect_1:GetEndTime())
    else
      self:PlayAnimation(self.Unselect_2, self.Unselect_2:GetEndTime())
    end
    self.IconView:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Title:SetText(self.conf.display_name)
    self.RedPoint:SetupKey(0)
    self.RedPoint_1:SetupKey(456, {
      Enum.TeachingType.TT_COMBAT_MECHANISM,
      self.data.id
    })
  end
end

function UMG_TeachingSubPanelTab_C:OnItemSelected(_bSelected)
  if _bSelected then
    if self.data then
      _G.NRCModuleManager:GetModule("MagicManualModule"):DispatchEvent(MagicManualModuleEvent.UpdateTeachTableView, self.type, self.data, self.conf)
    end
    self:StopAllAnimations()
    if self.data and not self.data.is_unlock then
      self:PlayAnimation(self.Select_1)
    else
      self:PlayAnimation(self.Select)
    end
  else
    self:StopAllAnimations()
    if self.data and not self.data.is_unlock then
      self:PlayAnimation(self.Unselect_2)
    else
      self:PlayAnimation(self.Unselect_1)
    end
  end
end

function UMG_TeachingSubPanelTab_C:OnTouchEnded(MyGeometry, InTouchEvent)
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  if self.RedPoint:IsRed() then
    local req = _G.ProtoMessage:newZoneTypeAdvantageTeachingReadReq()
    req.id = self.data.id
    _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_TYPE_ADVANTAGE_TEACHING_READ_REQ, req)
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TeachingSubPanelTab_C:OnTouchEnded")
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_TeachingSubPanelTab_C:OnDeactive()
end

return UMG_TeachingSubPanelTab_C
