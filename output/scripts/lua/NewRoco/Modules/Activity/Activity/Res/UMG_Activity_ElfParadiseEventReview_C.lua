local UMG_Activity_ElfParadiseEventReview_C = _G.NRCPanelBase:Extend("UMG_Activity_ElfParadiseEventReview_C")

function UMG_Activity_ElfParadiseEventReview_C:OnConstruct()
  self:SetChildViews(self.PopUp)
end

function UMG_Activity_ElfParadiseEventReview_C:OnActive(_lottery_records)
  local PetTripActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_PET_TRIP)
  if PetTripActivityInst and #PetTripActivityInst > 0 then
    self.activityInst = PetTripActivityInst[1]
  end
  if self.activityInst then
    local lottery_records = _lottery_records or {}
    self.ItemWidgetList = {}
    self.ItemDataList = {}
    for i, record in ipairs(lottery_records) do
      if record.activity_id ~= self.activityInst:GetActivityId() then
        local ItemWidget = UE4.UWidgetBlueprintLibrary.Create(self, self.ItemClass)
        if ItemWidget then
          local slot = self.List:AddChild(ItemWidget)
          table.insert(self.ItemWidgetList, ItemWidget)
          table.insert(self.ItemDataList, record)
          ItemWidget:OnItemUpdate(record, nil, #self.ItemDataList)
        end
      end
    end
  end
  self:LoadAnimation(0)
  self:SetCommonPopUpInfo(self.PopUp)
end

function UMG_Activity_ElfParadiseEventReview_C:OnPcClose()
  self:OnCloseBtn()
end

function UMG_Activity_ElfParadiseEventReview_C:SetCommonPopUpInfo(PopUp)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnCloseBtn
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_Activity_ElfParadiseEventReview_C:OnCloseBtn()
  self:LoadAnimation(2)
end

function UMG_Activity_ElfParadiseEventReview_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_Activity_ElfParadiseEventReview_C:OnDeactive()
end

function UMG_Activity_ElfParadiseEventReview_C:OnAddEventListener()
end

return UMG_Activity_ElfParadiseEventReview_C
