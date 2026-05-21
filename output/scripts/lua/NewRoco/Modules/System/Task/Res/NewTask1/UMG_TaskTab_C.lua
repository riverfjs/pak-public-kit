local TaskEnum = require("NewRoco.Modules.Core.Battle.Common.TaskEnum")
local UMG_TaskTab_C = _G.NRCViewBase:Extend("UMG_TaskTab_C")

function UMG_TaskTab_C:Construct()
  self.List = {}
  self.Unit = nil
  self.TaskList = nil
  self.IsExpand = false
  self:OnAddEventListener()
end

function UMG_TaskTab_C:Destruct()
  self.OperationBtn.OnClicked:Remove(self, self.OnOperationBtn)
end

function UMG_TaskTab_C:OnActive()
end

function UMG_TaskTab_C:Deactive()
end

function UMG_TaskTab_C:OnAddEventListener()
  self.OperationBtn.OnClicked:Add(self, self.OnOperationBtn)
end

function UMG_TaskTab_C:SetAllTabData(TaskList)
  self.TaskList = TaskList
  self.List = {}
  self:SetInfo()
end

function UMG_TaskTab_C:SetRestsTabData(Unit)
  self.Unit = Unit
  self.List = {}
  self:SetInfo()
end

function UMG_TaskTab_C:SetInfo()
  local CurSelectTabIndex = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetSelectTaskTabIndex)
  if CurSelectTabIndex == TaskEnum.TaskTab.All then
    self:HideUnit(true)
    self.List = self:HideFinishParagraph()
    self:InitRedPoint()
    self.MainPlotList:InitGridView(self.List)
    self:NotUnitPlayAnim()
  elseif self.Unit.IsHasUnit then
    self:PlayAnimation(self.In)
    for i, Paragraph in ipairs(self.Unit.ParagraphList) do
      table.insert(self.List, Paragraph.ParagraphInfo)
    end
    self:InitRedPoint()
    self.MainPlotList:InitGridView(self.List)
    self:HideChildItem()
    self:HideUnit(false)
    self:SetUnitInfo()
  else
    table.insert(self.List, self.Unit.ParagraphInfo)
    self:InitRedPoint()
    self.MainPlotList:InitGridView(self.List)
    self:HideUnit(true)
    self:NotUnitPlayAnim()
  end
end

function UMG_TaskTab_C:InitRedPoint()
  local TaskRedPointList = _G.NRCModeManager:DoCmd(TaskModuleCmd.GetTaskRedPointList)
  if not TaskRedPointList or #TaskRedPointList <= 0 then
    return
  end
  for i, TaskRedPoint in ipairs(TaskRedPointList) do
    local TaskConf = _G.DataConfigManager:GetTaskConf(tonumber(TaskRedPoint))
    if not TaskConf then
      break
    end
    for i, Task in ipairs(self.List) do
      if TaskConf.paragraph_id == Task.paragraph then
        if not Task.TaskRedList then
          Task.TaskRedList = {}
        end
        table.insert(Task.TaskRedList, TaskConf.id)
      end
    end
  end
end

function UMG_TaskTab_C:HideFinishParagraph()
  local ParagraphList = {}
  for i, Paragraph in ipairs(self.TaskList.AllParagraph) do
    if Paragraph.Type ~= TaskEnum.TaskParagraphFinishState.done then
      table.insert(ParagraphList, Paragraph)
    end
  end
  return ParagraphList
end

function UMG_TaskTab_C:OnOperationBtn()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40006004, "UMG_NPCShopItem_1_C:OnBtnDelItemClick")
  if self.IsExpand then
    self:Indentation()
  else
    self:Expand()
  end
end

function UMG_TaskTab_C:HideChildItem()
  for i, Task in ipairs(self.List) do
    local Item = self.MainPlotList:GetItemByIndex(i - 1)
    Item:HideItem()
  end
end

function UMG_TaskTab_C:NotUnitPlayAnim()
  Log.Dump(self.List, 3, "UMG_TaskTab_C:NotUnitPlayAnim")
  for i, Task in ipairs(self.List) do
    local Item = self.MainPlotList:GetItemByIndex(i - 1)
    Item:PlayNotUnitAnim()
  end
end

function UMG_TaskTab_C:Expand()
  self.IsExpand = true
  self.MainPlotTriangle:SetRenderScale(UE4.FVector2D(1, 1))
  for i, Task in ipairs(self.List) do
    local Item = self.MainPlotList:GetItemByIndex(i - 1)
    if Item then
      Item:StopAllAnimations()
      Item:PlayIn()
    end
  end
end

function UMG_TaskTab_C:Indentation()
  self.IsExpand = false
  self.MainPlotTriangle:SetRenderScale(UE4.FVector2D(1, -1))
  for i = #self.List, 1, -1 do
    local Item = self.MainPlotList:GetItemByIndex(i - 1)
    if Item then
      Item:StopAllAnimations()
      Item:PlayOut()
    end
  end
end

function UMG_TaskTab_C:CanCelSelect()
  for i, Task in ipairs(self.List) do
    local Item = self.MainPlotList:GetItemByIndex(i - 1)
    Item:SelectedItem(false)
    Item:SetOnNewStateRemove()
  end
end

function UMG_TaskTab_C:HideUnit(_IsHide)
  if _IsHide then
    self.UnitInfo:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.UnitInfo:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_TaskTab_C:IsSeasonTask()
  if not self.Unit then
    return
  end
  local IsHas = false
  if self.Unit.IsHasUnit and self.Unit.ParagraphList then
    for i, Paragraph in ipairs(self.Unit.ParagraphList) do
      local ParagraphConf = _G.DataConfigManager:GetParagraphConf(Paragraph.ParagraphInfo.paragraph)
      if ParagraphConf.season_task then
        return true
      end
    end
  elseif self.Unit.ParagraphInfo then
    local ParagraphConf = _G.DataConfigManager:GetParagraphConf(self.Unit.ParagraphInfo.paragraph)
    if ParagraphConf.season_task then
      return true
    end
  end
  return false
end

function UMG_TaskTab_C:SetUnitInfo()
  self.MainPlotTItle:SetText(self.Unit.UnitConf.title)
  self.SeasonTag:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self:IsSeasonTask() and self.Unit.UnitConf.unit_background then
    self.SeasonTag:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SetSeasonTag(UE4.UNRCStatics.HexToLinearColor("#2E8CAEFF"), self.Unit.UnitConf.unit_background)
  end
end

function UMG_TaskTab_C:SetSeasonTag(InColorAndOpacity, Path)
  self.SeasonTag:SetColorAndOpacity(InColorAndOpacity)
  self.SeasonTag:SetPath(Path)
end

function UMG_TaskTab_C:SetSelectParagraph(_IsSelect, _TaskId, OpenParagraph, IsFirstOpen)
  local TaskList = self.List
  local ParagraphId
  if OpenParagraph then
    ParagraphId = OpenParagraph
  elseif _TaskId then
    local TaskConf = _G.DataConfigManager:GetTaskConf(_TaskId)
    ParagraphId = TaskConf.paragraph_id
  else
    local TrackTask = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetTrackTask)
    ParagraphId = TrackTask and TrackTask.ParagraphConf and TrackTask.ParagraphConf.id
  end
  for i, Task in ipairs(TaskList) do
    if ParagraphId then
      if Task.paragraph == ParagraphId then
        if _IsSelect then
          self.MainPlotList:SelectItemByIndex(i - 1)
        end
        return true, i
      end
    else
      if 0 == Task.Type and IsFirstOpen then
        self.MainPlotList:SelectItemByIndex(i - 1)
        return true, i
      end
      return false, 0
    end
  end
  return false, 0
end

function UMG_TaskTab_C:GetCurrentSelectParagraph(ParagraphInfo)
  local TaskList = self.List
  for i, Task in ipairs(TaskList) do
    if ParagraphInfo and Task.paragraph == ParagraphInfo.paragraph then
      self:SetSelectColor(UE4.UNRCStatics.HexToLinearColor("#f4eee1ff"))
      if self:IsSeasonTask() then
        self:SetSeasonTag(UE4.UNRCStatics.HexToLinearColor("#C2D3D2FF"), self.Unit.UnitConf.unit_background2)
      end
      return
    end
  end
  self:SetSelectColor(UE4.UNRCStatics.HexToLinearColor("#42a7ccff"))
  if self:IsSeasonTask() then
    self:SetSeasonTag(UE4.UNRCStatics.HexToLinearColor("#2E8CAEFF"), self.Unit.UnitConf.unit_background)
  end
  self:CanCelSelect()
end

function UMG_TaskTab_C:SetTrackTaskStateFromMap(rspId)
  local IsHaveTrackTask, EphemeralParagraphIndex = self:SetSelectParagraph(false)
  if IsHaveTrackTask then
    local TaskList = self.List
    local TaskConf = _G.DataConfigManager:GetTaskConf(rspId)
    if TaskConf then
      local ParagraphId = TaskConf.paragraph_id
      for i, Task in ipairs(TaskList) do
        if Task.paragraph == ParagraphId then
          local taskItem = self.MainPlotList:GetItemByIndex(i - 1)
          taskItem:SetTrackTaskState(false)
        end
      end
    end
    local Item = self.MainPlotList:GetItemByIndex(EphemeralParagraphIndex - 1)
    if Item then
      Item:SetTrackTaskState(true)
    end
  else
    local TaskList = self.List
    local TaskConf = _G.DataConfigManager:GetTaskConf(rspId)
    if TaskConf then
      local ParagraphId = TaskConf.paragraph_id
      for i, Task in ipairs(TaskList) do
        if Task.paragraph == ParagraphId then
          local Item = self.MainPlotList:GetItemByIndex(i - 1)
          Item:SetTrackTaskState(false)
        end
      end
    end
  end
end

function UMG_TaskTab_C:SetTrackTaskState()
  local IsHaveTrackTask, EphemeralParagraphIndex = self:SetSelectParagraph(false)
  if IsHaveTrackTask then
    local Item = self.MainPlotList:GetItemByIndex(EphemeralParagraphIndex - 1)
    if Item then
      Item:SetTrackTaskState(false)
    end
  end
end

function UMG_TaskTab_C:SetSelectColor(Tone)
  self.MainPlotBg:SetColorAndOpacity(Tone)
end

function UMG_TaskTab_C:GetTitleSizeY()
  local AbsoluteSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.UnitInfo:GetCachedGeometry())
  return AbsoluteSize.Y
end

function UMG_TaskTab_C:GetSizeY()
  local AbsoluteSize = UE4.USlateBlueprintLibrary.GetLocalSize(self:GetCachedGeometry())
  return AbsoluteSize.Y
end

function UMG_TaskTab_C:GetItemSizeY()
  return 100
end

function UMG_TaskTab_C:SelectFirstIndex()
  self.MainPlotList:SelectItemByIndex(0)
end

function UMG_TaskTab_C:OnAnimationFinished(Animation)
  if Animation == self.In then
    self:Expand()
  end
end

function UMG_TaskTab_C:GetList()
  return self.List
end

return UMG_TaskTab_C
