local NRCCachedItem = require("NewRoco.Modules.System.PGC.Res.FieldItems.Base.NRCCachedItem")
local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")
local UMG_DataItem_C = NRCCachedItem:Extend("UMG_DataItem_C")

function UMG_DataItem_C:OnAcquiredFromCache(OwnerView)
end

function UMG_DataItem_C:OnRecycledToCache(OwnerView)
end

function UMG_DataItem_C:OnItemUpdate(Data, OwnerView, Index)
  self.Index = Index
  self.Data = Data
  if self.Data then
    self:RefreshName()
    self:RefreshState()
    self.SelectedState:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("FF00066A"))
  end
end

function UMG_DataItem_C:OnItemSelected(OwnerView, Index, Selected, ScrollChoose)
  if Selected then
    self.SelectedState:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("13FF006A"))
    NRCModuleManager:DoCmd(PGCModuleCmd.ShowDataDetail, self.Data)
    local PrimaryKeyValue = RTTIManager:GetPrimaryKeyValue(self.Data.TypeName, self.Data.Record)
    if PrimaryKeyValue then
      NRCModuleManager:DoCmd(PGCModuleCmd.ShowDataSummary, self.Data.TypeName, PrimaryKeyValue)
    end
  else
    self.SelectedState:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("FF00066A"))
  end
end

function UMG_DataItem_C:RefreshName()
  local editor_name = RTTIManager:GetProperty(self.Data.TypeName, self.Data.Record, "editor_name")
  local HasSet = false
  if editor_name then
    local really_name
    if type(editor_name) == "table" then
      really_name = editor_name[1]
    else
      really_name = editor_name
    end
    if type(really_name) == "string" and "" ~= really_name then
      self.Name:SetText(really_name)
      HasSet = true
    end
  end
  if not HasSet then
    local PrimaryKeyValue = RTTIManager:GetPrimaryKeyValue(self.Data.TypeName, self.Data.Record)
    if PrimaryKeyValue then
      self.Name:SetText(tostring(PrimaryKeyValue))
      HasSet = true
    end
  end
end

function UMG_DataItem_C:RefreshState()
  if RTTIBase.HasDataFlag(self.Data.Record, RTTIBase.DataFlagType.Create) then
    self.StateSwitcher:SetActiveWidgetIndex(2)
  elseif RTTIBase.HasDataFlag(self.Data.Record, RTTIBase.DataFlagType.Destroy) then
    self.StateSwitcher:SetActiveWidgetIndex(4)
  elseif RTTIBase.HasDataFlag(self.Data.Record, RTTIBase.DataFlagType.Dirty) then
    self.StateSwitcher:SetActiveWidgetIndex(3)
  else
    self.StateSwitcher:SetActiveWidgetIndex(1)
  end
end

return UMG_DataItem_C
