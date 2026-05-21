local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_BackflowContractManualTaskTab_C = Base:Extend("UMG_Activity_BackflowContractManualTaskTab_C")

function UMG_Activity_BackflowContractManualTaskTab_C:OnItemUpdate(_data, datalist, index)
  self.bItemSelected = false
  self.uiData = _data
  self.index = index
  self.Title:SetText(_data.text)
  self:StopAllAnimations()
  self:PlayAnimation(self.Cancel, self.Cancel:GetEndTime() - 0.01)
  self.redPointNew:SetupKey(474, {
    _data.activity_id,
    3 - index
  })
end

function UMG_Activity_BackflowContractManualTaskTab_C:OnItemSelected(_bSelected)
  if self.bItemSelected == _bSelected then
    return
  end
  self.bItemSelected = _bSelected
  self:StopAllAnimations()
  if _bSelected then
    self.uiData.callBack(self.uiData.caller, self.index)
    _G.NRCAudioManager:PlaySound2DAuto(40004006, "UMG_Activity_BackflowContractManualTaskTab_C:OnItemSelected")
    self:PlayAnimation(self.Select)
  else
    self:PlayAnimation(self.Cancel)
  end
end

function UMG_Activity_BackflowContractManualTaskTab_C:EraseRedPoint()
  if self.redPointNew:IsRed() then
    self.redPointNew:EraseRedPoint(true)
  end
end

return UMG_Activity_BackflowContractManualTaskTab_C
