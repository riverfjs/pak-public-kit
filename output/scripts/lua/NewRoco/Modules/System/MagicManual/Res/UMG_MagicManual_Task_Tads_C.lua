local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local MagicManualModuleEvent = require("NewRoco.Modules.System.MagicManual.MagicManualModuleEvent")
local UMG_MagicManual_Task_Tads_C = Base:Extend("UMG_MagicManual_Task_Tads_C")

function UMG_MagicManual_Task_Tads_C:OnConstruct()
end

function UMG_MagicManual_Task_Tads_C:OnDestruct()
end

function UMG_MagicManual_Task_Tads_C:OnItemUpdate(_data, datalist, index)
  self.SelectLoopTimer = 8
  self.data = _data
  self.index = index
  self:SetInfo()
end

function UMG_MagicManual_Task_Tads_C:SetInfo()
  local data = self.data
  self.Ordinary:SetPath(data.Icon)
  self.Special1:SetPath(data.UnderlayPath)
  local moduleData = _G.NRCModuleManager:GetModule("MagicManualModule"):GetData("MagicManualModuleData")
  if self.data.Sort == moduleData.TaskSortType.Task_Adventure then
    self.Dot:SetupKey(160)
    self.Dot_1:SetupKey(160)
  elseif self.data.Sort == moduleData.TaskSortType.Task_Daily then
    self.Dot:SetupKey(164)
    self.Dot_1:SetupKey(164)
  elseif self.data.Sort == moduleData.TaskSortType.PVP_Challenge then
    self.Dot:SetupKey(387)
    self.Dot_1:SetupKey(387)
  elseif self.data.Sort == moduleData.TaskSortType.Task_Challenge then
    self.Dot:SetupKey(263)
    self.Dot_1:SetupKey(263)
  elseif self.data.Sort == moduleData.TaskSortType.PVE_Challenge then
    self.Dot:SetupKey(367)
    self.Dot_1:SetupKey(367)
  elseif self.data.Sort == moduleData.TaskSortType.Teach then
    self.Dot:SetupKey(435)
    self.Dot_1:SetupKey(435)
  end
  self:LoadAnimation(0)
  if data.open == true then
    self:SetIsEnabled(true)
  else
    self:SetIsEnabled(false)
  end
end

function UMG_MagicManual_Task_Tads_C:SelectTaskType(_bSelected)
  if self and UE4.UObject.IsValid(self) then
    self:StopAllAnimations()
    if _bSelected then
      self:LoadAnimation(1)
      _G.NRCModuleManager:GetModule("MagicManualModule"):DispatchEvent(MagicManualModuleEvent.UpdateTableView, self.data.Sort, self.data.TaskTypeName)
    else
      self:LoadAnimation(3)
    end
  end
end

function UMG_MagicManual_Task_Tads_C:OnItemSelected(_bSelected)
  self:StopAllAnimations()
  self:CancelPlayLoopAnim()
  self:SelectTaskType(_bSelected)
end

function UMG_MagicManual_Task_Tads_C:OnDeactive()
end

function UMG_MagicManual_Task_Tads_C:StartPlayLoopAnim()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self:LoadAnimation(2)
  self.loopFuncID = nil
end

function UMG_MagicManual_Task_Tads_C:CancelPlayLoopAnim()
  if self.loopFuncID then
    DelayManager:CancelDelayById(self.loopFuncID)
    self.loopFuncID = nil
  end
end

function UMG_MagicManual_Task_Tads_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(1) then
    self:LoadAnimation(2)
  elseif anim == self:GetAnimByIndex(2) then
    self:CancelPlayLoopAnim()
    self.loopFuncID = DelayManager:DelaySeconds(self.SelectLoopTimer, self.StartPlayLoopAnim, self)
  end
end

function UMG_MagicManual_Task_Tads_C:OnDestruct()
  self:CancelPlayLoopAnim()
end

return UMG_MagicManual_Task_Tads_C
