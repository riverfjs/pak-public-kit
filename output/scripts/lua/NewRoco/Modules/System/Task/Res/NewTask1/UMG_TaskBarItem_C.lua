local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local TaskEnum = require("NewRoco.Modules.Core.Battle.Common.TaskEnum")
local UMG_TaskBarItem_C = Base:Extend("UMG_TaskBarItem_C")

function UMG_TaskBarItem_C:OnConstruct()
end

function UMG_TaskBarItem_C:OnDestruct()
  if self.DelayId then
    DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
end

function UMG_TaskBarItem_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  self.datalist = datalist
  self.IsExpand = false
  self.TaskRedList = _data.TaskRedList
  self:initializePanelInfo()
  self:SetRedPoint()
  self:SetInfo()
end

function UMG_TaskBarItem_C:SetRedPoint()
  if not self.TaskRedList then
    return
  end
  for i, TaskRed in ipairs(self.TaskRedList) do
    self.RedPoint:SetupKey(221, TaskRed)
  end
end

function UMG_TaskBarItem_C:SetOnNewStateRemove()
  local EraseRedList = {}
  if self.TaskRedList and #self.TaskRedList > 0 then
    for i, TaskRed in ipairs(self.TaskRedList) do
      table.insert(EraseRedList, {
        tostring(TaskRed)
      })
    end
    self.TaskRedList = nil
  end
  _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPointWithExtraKeyList, 221, EraseRedList)
end

function UMG_TaskBarItem_C:HideItem()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_TaskBarItem_C:PlayNotUnitAnim()
  self:SetVisibility(UE4.ESlateVisibility.Visible)
  self:PlayAnimation(self.In2)
end

function UMG_TaskBarItem_C:PlayIn()
  self.DelayId = _G.DelayManager:DelaySeconds(0.05 * (self.index - 1), function()
    self.IsExpand = true
    self:SetVisibility(UE4.ESlateVisibility.Visible)
    self:PlayAnimation(self.In)
  end)
end

function UMG_TaskBarItem_C:PlayOut()
  self.DelayId = _G.DelayManager:DelaySeconds(0.05 * (#self.datalist - self.index), function()
    self.IsExpand = false
    self:PlayAnimation(self.Out)
  end)
end

function UMG_TaskBarItem_C:GetSize()
  local AbsoluteSize = UE4.USlateBlueprintLibrary.GetAbsoluteSize(self:GetCachedGeometry())
  return AbsoluteSize
end

function UMG_TaskBarItem_C:GetIsActivityTask()
  local module = _G.NRCModuleManager:GetModule("TaskModule")
  if module then
    return module:GetIsActivityTaskByParagraphId(self.data.paragraph)
  end
  return false
end

function UMG_TaskBarItem_C:SetInfo()
  local data = self.data
  local ParagraphConf = _G.DataConfigManager:GetParagraphConf(data.paragraph)
  self.TitleText:SetText(ParagraphConf.title)
  if data.Type == TaskEnum.TaskParagraphFinishState.done then
    self.Finish:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if ParagraphConf.season_task then
    self.LimitedTime:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SeasonRCText:SetText(LuaText.task_limited_type_season)
  elseif self:GetIsActivityTask() then
    self.LimitedTime:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SeasonRCText:SetText(LuaText.task_limited_type_event)
  else
    self.LimitedTime:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local TrackTask = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetTrackTask)
  if TrackTask and TrackTask.ParagraphConf and TrackTask.ParagraphConf.id == data.paragraph then
    self.TraceIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SetOnNewStateRemove()
  end
  self:SetTraceIcon()
  self:SelectedItem(false)
end

function UMG_TaskBarItem_C:SetTraceIcon()
  local TrackTask = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetTrackTask)
  if TrackTask and TrackTask.ParagraphConf and TrackTask.ParagraphConf.id == self.data.paragraph then
    if TrackTask.Config.task_class == Enum.TaskClassType.TCT_JOURNEY then
      self.TraceIcon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Task/Raw/NewTask1/Frames/img_MainPlotIcon_png.img_MainPlotIcon_png'")
    elseif TrackTask.Config.task_class == Enum.TaskClassType.TCT_MAIN then
      self.TraceIcon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Task/Raw/NewTask1/Frames/img_BranchIcon_png.img_BranchIcon_png'")
    elseif TrackTask.Config.task_class == Enum.TaskClassType.TCT_SUB then
      self.TraceIcon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Task/Raw/NewTask1/Frames/img_EntrustIcon_png.img_EntrustIcon_png'")
    end
  end
end

function UMG_TaskBarItem_C:initializePanelInfo()
  self.Finish:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TraceIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_TaskBarItem_C:SetTrackTaskState(_IsTrack)
  if _IsTrack then
    if not self:IsAnimationPlaying(self.Track_in) then
      self:StopAllAnimations()
      self.TraceIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:SetTraceIcon()
      self:PlayAnimation(self.Track_in)
    end
  elseif not self:IsAnimationPlaying(self.Track_out) then
    self:StopAllAnimations()
    self:PlayAnimation(self.Track_out)
  end
end

function UMG_TaskBarItem_C:SelectedItem(_bSelected)
  if _bSelected then
    self.SeasonRCText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#F4EEE2FF"))
    self.Bg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#F4EEE1FF"))
    self.Bg1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#C2D3D2FF"))
    self.TitleText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#18627DFF"))
    self.Finish:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Task/Raw/NewTask1/Frames/img_TaskBarFinishBg1_png.img_TaskBarFinishBg1_png'")
  else
    self.SeasonRCText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#42A7CCFF"))
    if self.Bg then
      self.Bg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#18627DFF"))
    end
    if self.Bg1 then
      self.Bg1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#227391FF"))
    end
    if self.TitleText then
      self.TitleText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#42A7CCFF"))
    end
    self.Finish:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Task/Raw/NewTask1/Frames/img_TaskBarFinishBg_png.img_TaskBarFinishBg_png'")
  end
end

function UMG_TaskBarItem_C:OnItemSelected(_bSelected)
  self:SelectedItem(_bSelected)
  if _bSelected then
    _G.NRCModuleManager:DoCmd(TaskModuleCmd.SelectTaskParagraph, self.data)
  else
    self:SetOnNewStateRemove()
  end
end

function UMG_TaskBarItem_C:OnAnimationFinished(Anim)
  if Anim == self.In and not self.IsExpand then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif Anim == self.Out then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif Anim == self.Track_out then
    self.TraceIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TaskBarItem_C:OnDeactive()
end

return UMG_TaskBarItem_C
