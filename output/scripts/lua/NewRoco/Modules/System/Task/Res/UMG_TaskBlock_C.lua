local Base = _G.NRCUmgClass
local UMG_TaskBlock_C = Base:Extend("UMG_TaskBlock_C")

function UMG_TaskBlock_C:Ctor()
  Base.Ctor(self)
  self.IsSelected = false
  self.IsCollapsed = false
  self.IsMouseDown = false
  self.isPlayMedia = false
  self.playMediaTime = 0
  self.expandNum = 0
  self.timer = 0
  self.isShowMedia = false
end

function UMG_TaskBlock_C:Construct()
  local data = {
    LuaText.Task_story_missions,
    "story missions"
  }
  local data1 = {
    LuaText.Task_side_missions,
    "side missions"
  }
  local data2 = {
    LuaText.Task_Trial_missions,
    "Trial missions"
  }
  self.titleTex = {
    data,
    data1,
    data2
  }
  self.MediaPath = {
    "./Movies/taskzhuxian.mp4",
    "./Movies/taskzhixian.mp4",
    "./Movies/taskshilian.mp4"
  }
  self.Media1List = {
    self.Media1,
    self.Media2,
    self.Media3
  }
  for i = 1, #self.Media1List do
    self.Media1List[i].RestartBtn:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.Media1List[i]:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  UpdateManager:Register(self)
  self.DelayShowMediaId = _G.DelayManager:DelayFrames(10, function()
    self:ShowMedia()
  end)
end

function UMG_TaskBlock_C:PlayMediaInit(index)
  for i = 1, #self.Media1List do
    local item = self.Media1List[i]
    if i == index then
      self.curMedia1 = item
      self:PlayMedia(item, self.MediaPath[i], true, true, true)
    end
    item:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_TaskBlock_C:Destruct()
  UpdateManager:UnRegister(self)
  self.Parent = nil
  if self.DelayShowMediaId then
    _G.DelayManager:CancelDelayById(self.DelayShowMediaId)
    self.DelayShowMediaId = nil
  end
end

function UMG_TaskBlock_C:SetData(Data, index)
  self.CurrentData = Data
  self.index = index
  self:PlayMediaInit(self.index)
  self.UMG_Task_UIiconAn:UIiconAnInit(self.index)
  self:SetItemSelected(self.IsSelected)
  self:SetItemCollapsed(self.IsCollapsed)
  self:SetTextDes(self.titleTex[index][1], self.titleTex[index][2])
  if 0 == #self.CurrentData.List then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    self:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_TaskBlock_C:OnClick()
  local WasSelected = self.IsSelected
  self.Parent:SetSelectBlock(self.CurrentData)
  if self.IsSelected then
    if self.IsCollapsed then
      _G.NRCAudioManager:PlaySound2DAuto(1081, "UMG_TaskBlock_C:OnClick Close")
    else
      _G.NRCAudioManager:PlaySound2DAuto(1080, "UMG_TaskBlock_C:OnClick Open")
    end
  else
  end
end

function UMG_TaskBlock_C:PlayMedia(media, source, isFile, needAutoPlay, isLoop)
  media:OpenMediaPanel(source, needAutoPlay, isLoop)
end

function UMG_TaskBlock_C:SetItemSelected(selected)
  if selected and self.IsSelected == false then
    self.UMG_Task_UIiconAn:PlayChange1()
    self:PlayAnimation(self.change1)
  elseif not selected and self.IsSelected == true then
    self:PlayAnimation(self.change2)
    self.UMG_Task_UIiconAn:PlayChange2()
  end
  self.IsSelected = selected
  self.TaskTypeIcon:SetPath(self.CurrentData.Style.normal_item)
  if self.IsSelected == true then
    self:SetItemCollapsed(not self.IsCollapsed)
  else
    self:SetItemCollapsed(true)
  end
end

function UMG_TaskBlock_C:SetItemCollapsed(collapsed)
  self.IsCollapsed = collapsed
  if not self.IsCollapsed then
    self.TaskList:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCImage_listBg:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if 0 == #self.CurrentData.List then
    self.NRCImage_listBg:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  self.expandNum = 0
  self:StarPlayMedia()
end

function UMG_TaskBlock_C:SetSelectTask(Task)
  for _, TaskView in wpairs(self.TaskList) do
    TaskView:SetItemSelected(Task == TaskView.CurrentData)
  end
  if Task then
    self.Parent:SetCurrentTask(Task)
  end
end

function UMG_TaskBlock_C:RefreshTaskList(ForceSelect)
  self.TaskList:ClearChildren()
  for Index, Task in ipairs(self.CurrentData.List) do
    local TaskView = UE4.UWidgetBlueprintLibrary.Create(self, self.TaskBlockItemTemplate)
    local Slot = self.TaskList:AddChild(TaskView)
    Slot:SetHorizontalAlignment(UE4.EHorizontalAlignment.HAlign_Left)
    TaskView.Parent = self
    TaskView:SetData(Task)
    if self.IsSelected and Task.Info.is_track or ForceSelect then
      self:SetSelectTask(Task)
    end
  end
end

function UMG_TaskBlock_C:Refresh()
  for _, TaskView in wpairs(self.TaskList) do
    TaskView:Refresh()
  end
end

function UMG_TaskBlock_C:OnMouseButtonDown(MyGeometry, MouseEvent)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_TaskBlock_C:OnMouseButtonUp(MyGeometry, MouseEvent)
  self:OnClick()
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_TaskBlock_C:SetTextDes(title, ten)
  self.NRCText_Nor1:SetText(title)
  self.NRCText_Nor2:SetText(ten)
  self.NRCText_Select1:SetText(title)
  self.NRCText_Select2:SetText(ten)
end

function UMG_TaskBlock_C:StarPlayMedia()
  if self.IsSelected and self.IsCollapsed == false and self.isShowMedia == true then
    if not self.isPlayMedia then
      self.TaskTypeIcon:SetVisibility(UE4.ESlateVisibility.Hidden)
      self.curMedia1:SetVisibility(UE4.ESlateVisibility.Visible)
      self.curMedia1:Replay()
      self.isPlayMedia = true
      self.playMediaTime = 2.9
    end
  else
    if self.isPlayMedia then
      self.isPlayMedia = false
      self.curMedia1:Pause()
    end
    self:StopAnimation(self.ImageDisappear)
    self.TaskTypeIcon:SetRenderOpacity(1)
    self.TaskTypeIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    self.curMedia1:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_TaskBlock_C:OnTick(InDeltaTime)
  if self.isPlayMedia and self.playMediaTime > 0 then
    self.playMediaTime = self.playMediaTime - InDeltaTime
    if self.playMediaTime <= 0 then
      self.curMedia1:Pause()
      self.isPlayMedia = false
    end
  end
  if not self.IsCollapsed then
    self:Expand(InDeltaTime)
  else
    self:Indentation(InDeltaTime)
  end
end

function UMG_TaskBlock_C:Expand(InDeltaTime)
  if self.expandNum > 999 then
    return
  end
  if self.expandNum < 1 then
    self.expandNum = self.expandNum + 1
    self.timer = 0
    return
  end
  if 1 == self.expandNum then
    local size = self.TaskList:GetDesiredSize()
    size.y = size.y
    self.maxSize = size
    self.expandNum = self.expandNum + 1
  end
  self.timer = self.timer + InDeltaTime
  local size = self.CanvasPanel_size.Slot:GetSize()
  if self.timer >= self.animaTime then
    self.expandNum = 1000
    size.y = self.maxSize.y
  else
    local localSizePro = self.openAndCloseCurve:GetFloatValue(self.timer)
    size.y = self.maxSize.y * (1 - localSizePro)
  end
  self.CanvasPanel_size.Slot:SetSize(size)
end

function UMG_TaskBlock_C:Indentation(InDeltaTime)
  if self.TaskList.Visibility == UE4.ESlateVisibility.Collapsed then
    return
  end
  if self.expandNum < 1 then
    self.expandNum = self.expandNum + 1
    self.timer = 0
    local size = self.TaskList:GetDesiredSize()
    size.y = size.y
    self.maxSize = size
    return
  end
  local size = self.TaskList.Slot:GetSize()
  self.timer = self.timer + InDeltaTime
  if self.timer >= self.animaTime then
    size.y = 0
  else
    local localSizePro = self.openAndCloseCurve:GetFloatValue(self.timer)
    size.y = self.maxSize.y * localSizePro
  end
  self.CanvasPanel_size.Slot:SetSize(size)
  if 0 == size.y then
    self.TaskList:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_listBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TaskBlock_C:ShowMedia()
  self.isShowMedia = true
  if self.IsSelected and self.IsCollapsed == false and not self.isPlayMedia then
    self:PlayAnimation(self.ImageDisappear)
    self.curMedia1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.curMedia1:Replay()
    self.isPlayMedia = true
    self.playMediaTime = 2.9
  end
end

function UMG_TaskBlock_C:StarClose()
  self.TaskTypeIcon:SetRenderOpacity(1)
  self.TaskTypeIcon:SetVisibility(UE4.ESlateVisibility.Visible)
  self.curMedia1:SetVisibility(UE4.ESlateVisibility.Hidden)
end

return UMG_TaskBlock_C
