local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_ElfAdventurePetIcon_C = Base:Extend("UMG_Activity_ElfAdventurePetIcon_C")

function UMG_Activity_ElfAdventurePetIcon_C:OnConstruct()
end

function UMG_Activity_ElfAdventurePetIcon_C:OnDestruct()
end

function UMG_Activity_ElfAdventurePetIcon_C:OnItemUpdate(_data, datalist, index)
  self.parent = _data.Parent
  self.UiData = _data.Data
  self.IsSelect = _data.IsSelect
  if self.UiData and self.parent then
    local pet_data = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.UiData.pet_gid)
    if not pet_data then
      Log.Error("UMG_Activity_ElfAdventurePetIcon_C:OnItemUpdate", "pet_data is nil")
      return
    end
    self.ColorfulHeadIcon:SetIconPathAndMaterial(pet_data.base_conf_id, pet_data.mutation_type, pet_data.glass_info)
    if self.UiData.max_trip_time and self.UiData.max_trip_time > 0 then
      local _seconds = self.UiData.max_trip_time
      local day = _seconds // 86400
      local hour = (_seconds - 86400 * day) // 3600
      local time_text = string.format(_G.LuaText.bp_time_left, hour)
      self.Time:SetText(time_text)
    end
  end
  if self.IsSelect then
    self.SelectBg:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.SelectBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_ElfAdventurePetIcon_C:UpdateSelected(IsSelect)
  if IsSelect == self.IsSelect then
    return
  end
  self.IsSelect = IsSelect
  if self.IsSelect then
    self.SelectBg:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.SelectBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_ElfAdventurePetIcon_C:OnItemSelected(_bSelected)
end

function UMG_Activity_ElfAdventurePetIcon_C:OpItem(_bSelected)
  if _bSelected then
    self.SelectBg:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.SelectBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_ElfAdventurePetIcon_C:OnTouchEnded(MyGeometry, InTouchEvent)
  if self.IsSelect then
    _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Activity_ElfAdventurePetIcon_C:BroadcastOnClicked")
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_ElfAdventurePetIcon_C:BroadcastOnClicked")
  end
  self.parent:OnSelectPet(self.UiData.pet_gid)
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_Activity_ElfAdventurePetIcon_C:OnDeactive()
end

return UMG_Activity_ElfAdventurePetIcon_C
