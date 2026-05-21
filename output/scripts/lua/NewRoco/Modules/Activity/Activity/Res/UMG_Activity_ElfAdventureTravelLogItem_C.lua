local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_ElfAdventureTravelLogItem_C = Base:Extend("UMG_Activity_ElfAdventureTravelLogItem_C")

function UMG_Activity_ElfAdventureTravelLogItem_C:OnConstruct()
end

function UMG_Activity_ElfAdventureTravelLogItem_C:OnDestruct()
end

function UMG_Activity_ElfAdventureTravelLogItem_C:OnItemUpdate(_data, datalist, index)
  self.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(_data.pet_gid)
  self.TextNum:SetText(_data.get_happy_value)
  local time_text = ActivityUtils.GetTimeFormatStr(_data.trip_max_time)
  self.TextTime:SetText(time_text)
  local date = ActivityUtils.ToTimeDetailData(_data.trip_end_time)
  local end_time_text = string.format(LuaText.Activity_Invite_friend_time, date.year, date.month, date.day, date.hour, date.minute, date.second)
  self.TextLeave:SetText(end_time_text)
  if self.petData then
    self.ColorfulHeadIcon:SetIconPathAndMaterial(self.petData.base_conf_id, self.petData.mutation_type, self.petData.glass_info)
  else
    self.ColorfulHeadIcon:SetIconPathAndMaterial(_data.pet_base_id, _data.mutation_type, _data.glass_info)
  end
end

function UMG_Activity_ElfAdventureTravelLogItem_C:OnItemSelected(_bSelected)
end

function UMG_Activity_ElfAdventureTravelLogItem_C:OnDeactive()
end

return UMG_Activity_ElfAdventureTravelLogItem_C
