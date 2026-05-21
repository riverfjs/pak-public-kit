local UMG_Activity_ElfAdventureTravelLog_C = _G.NRCPanelBase:Extend("UMG_Activity_ElfAdventureTravelLog_C")

function UMG_Activity_ElfAdventureTravelLog_C:OnConstruct()
  self:SetChildViews(self.PopUp)
end

function UMG_Activity_ElfAdventureTravelLog_C:OnActive()
  local PetTripActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_PET_TRIP)
  if PetTripActivityInst and #PetTripActivityInst > 0 then
    self.activityInst = PetTripActivityInst[1]
  end
  if self.activityInst then
    self.activityData = self.activityInst:GetActivityData()
    local list = self.activityData.pet_trip_record_info
    table.sort(list, function(a, b)
      return a.trip_end_time > b.trip_end_time
    end)
    self.List:InitList(list)
  else
    self:DoClose()
    return
  end
  self:LoadAnimation(0)
  self:SetCommonPopUpInfo(self.PopUp)
end

function UMG_Activity_ElfAdventureTravelLog_C:OnPcClose()
  self:OnCloseBtn()
end

function UMG_Activity_ElfAdventureTravelLog_C:SetCommonPopUpInfo(PopUp)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnCloseBtn
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_Activity_ElfAdventureTravelLog_C:OnCloseBtn()
  self:LoadAnimation(2)
end

function UMG_Activity_ElfAdventureTravelLog_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_Activity_ElfAdventureTravelLog_C:OnDeactive()
end

return UMG_Activity_ElfAdventureTravelLog_C
