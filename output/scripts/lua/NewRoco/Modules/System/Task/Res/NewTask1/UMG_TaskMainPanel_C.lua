local ShowID = RocoEnv.IS_EDITOR or not RocoEnv.IS_SHIPPING and _G.AppMain:HasLaunchParams()
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local TaskEnum = require("NewRoco.Modules.Core.Battle.Common.TaskEnum")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local UMG_TaskMainPanel_C = _G.NRCPanelBase:Extend("UMG_TaskMainPanel_C")

local function _TaskCompareAll(a, b)
  return a.paragraph < b.paragraph
end

function UMG_TaskMainPanel_C:OnConstruct()
  local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_TASK)
  _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_TASK)
  if StateGroup then
    _G.NRCAudioManager:BatchSetState(StateGroup)
  end
  self.TaskTabList = {
    self.AllTab,
    self.MainTab,
    self.BranchTab,
    self.EntrustTab
  }
  self.TaskTabCanvasList = {
    self.AllTabCanvas,
    self.MainTabCanvas,
    self.BranchTabCanvas,
    self.EntrustTabCanvas
  }
  self.AllTypeList = {
    self.MainPlottabList,
    self.BranchtabList,
    self.GleaningsTabList
  }
  self.AllTypeCanvas = {
    self.MainPlotCanvas,
    self.BranchCanvas,
    self.EntrustCanvas
  }
  self.AllTypeTitle = {
    self.MainPlotTitle,
    self.BranchTitle,
    self.EntrustTitle
  }
  self.RestsTypeList = {
    self.JourneyPlottabList,
    self.LegendarytabList,
    self.GleaningsTabList_1
  }
  self.AllTabWidgetList = {}
  self.RestsTabWidgetList = {}
  self.RestsTabWidgetList[TaskEnum.TaskTab.journey] = {}
  self.RestsTabWidgetList[TaskEnum.TaskTab.Legendary] = {}
  self.RestsTabWidgetList[TaskEnum.TaskTab.Gleanings] = {}
  self:SetChildViews(self.AllTab, self.MainTab, self.BranchTab, self.EntrustTab, self.UMG_TaskSummary_GroupPhoto, self.UMG_TaskSummary_GroupPhoto_1)
  self.data = self.module:GetData("TaskModuleData")
  self.data:SetSelectTaskTabIndex(-1)
  self.IsCanOnClick = false
  self.Task_Info = nil
  self.isTracking = false
  self.IsDisable = false
  self.TaskId = nil
  self.TaskConditionList = nil
  self.OldTaskInfo = nil
  self:OnAddEventListener()
  self:BindInputAction()
  self:SetCommonTitle()
  self.RightSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.btnClose:SetStyle(2)
  self.FirstSelectTaskTab = true
  self.ParagraphInfo = nil
  self.Task_Info = nil
  self:InitCtrlText()
end

function UMG_TaskMainPanel_C:InitCtrlText()
  self.MainPlotText1:SetText(LuaText.UMG_TaskMainPanel_text_1)
  self.BranchText:SetText(LuaText.UMG_TaskMainPanel_text_2)
  self.EntrustText:SetText(LuaText.UMG_TaskMainPanel_text_3)
  self.JourneyPlotText1:SetText(LuaText.UMG_TaskMainPanel_text_1)
  self.LegendaryText:SetText(LuaText.UMG_TaskMainPanel_text_2)
  self.GleaningsText:SetText(LuaText.UMG_TaskMainPanel_text_3)
  self.PlotText:SetText(LuaText.UMG_TaskMainPanel_text_1)
  self.QitanTitle:SetText("picture books")
  self.NRCText_2:SetText(LuaText.UMG_TaskMainPanel_text_4)
  self.NRCText_68:SetText(LuaText.UMG_TaskMainPanel_text_4)
end

function UMG_TaskMainPanel_C:OnDestruct()
  _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_TASK)
end

function UMG_TaskMainPanel_C:OnEnable()
  self:PlayEnVeLope()
  if self.shouldShowForNextEnable then
    self.shouldShowForNextEnable = false
    self:StopAnimation(self.Open)
    self:PlayAnimation(self.Open, 0, 1, 0, 1)
  end
end

function UMG_TaskMainPanel_C:OnDisable()
end

function UMG_TaskMainPanel_C:OnActive(TaskId)
  _G.NRCAudioManager:PlaySound2DAuto(1237, "UMG_TaskMainPanel_C:OnEnable")
  self.TaskId = TaskId
  self:HideTab()
  if 2 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self.TaskTabList[2]:OnTouchEnded()
  elseif 3 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self.TaskTabList[3]:OnTouchEnded()
  elseif self:IsHasParagraph() then
    self.TaskTabList[1]:OnTouchEnded()
  else
    self.TaskTabList[2]:OnTouchEnded()
  end
  self.shouldShowForNextEnable = false
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").TASKITEM
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
end

function UMG_TaskMainPanel_C:OnRefreshParagraph(tabIndex)
  if tabIndex >= 0 and tabIndex < #self.TaskTabList and tabIndex == TaskEnum.TaskTab.All then
    local BaseTaskList = self.data:GetBaseTaskList()
    for i, TaskList in ipairs(BaseTaskList) do
      if TaskList.AllParagraph and #TaskList.AllParagraph > 0 then
        table.sort(TaskList.AllParagraph, _TaskCompareAll)
        if self.AllTabWidgetList[TaskList.PanelIndex] then
          self.AllTabWidgetList[TaskList.PanelIndex].TaskList = TaskList
          self.AllTabWidgetList[TaskList.PanelIndex].TaskTabWidget:SetAllTabData(TaskList)
        end
      end
    end
    self:SetTaskTabSelectIndex(TaskTab, self.AllTabWidgetList)
  end
end

function UMG_TaskMainPanel_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_TaskUI")
  if mappingContext then
    mappingContext:BindAction("IA_CloseTaskUI", self, "OnPcClose")
    mappingContext:BindAction("IA_CloseTaskQuick", self, "OnPcClose")
  end
end

function UMG_TaskMainPanel_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:OnClickBtnClose()
end

function UMG_TaskMainPanel_C:IsHasParagraph()
  local BaseTaskList = self.data:GetBaseTaskList()
  for i, TaskList in ipairs(BaseTaskList) do
    if TaskList.AllParagraph and #TaskList.AllParagraph > 0 then
      return true
    end
  end
  return false
end

function UMG_TaskMainPanel_C:IsDoneParaGraph(Type, ParaGraphId)
  local BaseTaskList = self.data:GetBaseTaskList()
  if BaseTaskList[Type] and BaseTaskList[Type].done_paragraph and #BaseTaskList[Type].done_paragraph > 0 then
    for i, Task in ipairs(BaseTaskList[Type].done_paragraph) do
      if ParaGraphId == Task.paragraph then
        return true
      end
    end
  end
  return false
end

function UMG_TaskMainPanel_C:OnDeactive()
  GlobalConfig.OpenMainPanelFromDebugBtn = 0
  self.data:SetOpenTask(nil)
end

function UMG_TaskMainPanel_C:PlayEnVeLopeType()
  if self.IsDisable then
    if self:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      self:PlayEnVeLope()
    end
  else
    self:PlayEnVeLope()
  end
end

function UMG_TaskMainPanel_C:SetExpireTime(taskId)
  if UE4.UObject.IsValid(self.CanvasTime) then
    self.CanvasTime:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if taskId then
    local conf = _G.DataConfigManager:GetTaskConf(taskId)
    if conf and conf.expire_time_type and conf.expire_time_type == _G.Enum.TaskExpireTimeType.TETT_BAGITEM then
      local bagItemId = conf.expire_time_param
      local bagItemInfo = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, bagItemId)
      if bagItemInfo and UE4.UObject.IsValid(self.CanvasTime) then
        self.CanvasTime:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        local currentTimestamp = math.floor(_G.ZoneServer:GetServerTime() / 1000)
        if currentTimestamp > bagItemInfo.expire_time then
          self.NRCText_Time:SetText(LuaText.item_expired_text04)
        else
          local timeStr = os.date(LuaText.expire_task_txt, bagItemInfo.expire_time)
          self.NRCText_Time:SetText(timeStr)
        end
      end
    elseif conf and conf.expire_time_type and conf.expire_time_type == _G.Enum.TaskExpireTimeType.TETT_SEASON then
      local seasonId = conf.expire_time_param
      local seasonConf = _G.DataConfigManager:GetSeasonConf(seasonId)
      if seasonConf and UE4.UObject.IsValid(self.CanvasTime) then
        self.CanvasTime:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        local currentTimestamp = math.floor(_G.ZoneServer:GetServerTime() / 1000)
        local endTime = ActivityUtils.ToTimestamp(seasonConf.end_time)
        if currentTimestamp > endTime then
          self.NRCText_Time:SetText(LuaText.item_expired_text04)
        else
          local timeStr = os.date(LuaText.expire_task_txt, endTime)
          self.NRCText_Time:SetText(timeStr)
        end
      end
    end
  end
end

function UMG_TaskMainPanel_C:PlayEnVeLope()
  local MailTask = self.data:GetMailTask()
  if MailTask and 0 ~= MailTask.message_id then
    self.data:SetIsOpenTips(true)
    self.data:SetMailTask(nil)
    _G.NRCModeManager:DoCmd(TaskModuleCmd.lookLetter, MailTask.message_id)
  else
    local RandomSubTask = self.data:GetRandomSubTask()
    if RandomSubTask then
      self.data:SetIsOpenTips(true)
      _G.NRCModuleManager:DoCmd(TaskModuleCmd.OpenEnvelopePanel)
    end
  end
end

function UMG_TaskMainPanel_C:HideTab()
  self:CheckCanOpenNPC()
  local BaseTaskList = self.data:GetBaseTaskList()
  for i, TaskTab in ipairs(self.TaskTabList) do
    if BaseTaskList[i] and BaseTaskList[i].AllParagraph and self.TaskTabList[i + 1] then
      self.TaskTabCanvasList[i + 1]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.TaskTabList[i + 1]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif self.TaskTabList[i + 1] and self.TaskTabCanvasList[i + 1] then
      self.TaskTabList[i + 1]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.TaskTabCanvasList[i + 1]:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_TaskMainPanel_C:OnAddEventListener()
  self:AddButtonListener(self.MapBtn, self.OnClickMapBtn)
  self:AddButtonListener(self.MapBtn2, self.OnClickMapBtn)
  self:AddButtonListener(self.MapBtn1, self.OnClickMapBtn)
  self:AddButtonListener(self.btnClose.btnClose, self.OnClickBtnClose)
  self:AddButtonListener(self.TraceBtn.btnLevelUp, self.OnTrackBtn)
  self:AddButtonListener(self.TraceBtn1.btnLevelUp, self.OnTrackBtn)
  self:AddButtonListener(self.TraceBtn2.btnLevelUp, self.OnTrackBtn)
  self:AddButtonListener(self.LacquerBtn, self.OnLacquerBtn)
  self:AddButtonListener(self.LacquerBtn_1, self.OnLacquerBtn1)
  self:AddButtonListener(self.LacquerBtn_2, self.OnLacquerBtn1)
  self:AddButtonListener(self.CollectTab.ClickBtn, self.OnClickCollectBtn)
  self.CollectTab.ClickBtn.OnPressed:Add(self, self.OnClickBtnPressed)
  self.CollectTab.ClickBtn.OnReleased:Add(self, self.OnClickBtnReleased)
  self:RegisterEvent(self, TaskModuleEvent.ChangeTaskTab, self.OnChangeTaskTab)
  self:RegisterEvent(self, TaskModuleEvent.SelectTaskParagraph, self.OnSelectTaskParagraph)
  self:RegisterEvent(self, TaskModuleEvent.SubTaskTokenEvent, self.OnSubTaskTokenEvent)
  self:RegisterEvent(self, TaskModuleEvent.OpenJourneyEnvelope, self.OnOpenJourneyEnvelope)
  self:RegisterEvent(self, TaskModuleEvent.SetTrackTaskState, self.SetTrackTaskStateFromMap)
  self:RegisterEvent(self, TaskModuleEvent.NotOpenParagraph, self.OnNotOpenParagraph)
  self:RegisterEvent(self, TaskModuleEvent.ClearSelectState, self.ClearRestsSelect)
  self:RegisterEvent(self, TaskModuleEvent.OnRefreshTaskMainPanel, self.OnRefreshParagraph)
end

function UMG_TaskMainPanel_C:UpdateTaskSummaryGroupPhoto(uiData)
  if uiData then
    self.UMG_TaskSummary_GroupPhoto.UMG_TaskPhoto:OnAddEventListener()
    self.UMG_TaskSummary_GroupPhoto:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_TaskSummary_GroupPhoto:OnPlayTips(uiData)
    self.UMG_TaskSummary_GroupPhoto_1.UMG_TaskPhoto:OnAddEventListener()
    self.UMG_TaskSummary_GroupPhoto_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_TaskSummary_GroupPhoto_1:OnPlayTips(uiData)
  else
    self.UMG_TaskSummary_GroupPhoto.UMG_TaskPhoto:OnRemoveEventListener()
    self.UMG_TaskSummary_GroupPhoto:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_TaskSummary_GroupPhoto_1.UMG_TaskPhoto:OnRemoveEventListener()
    self.UMG_TaskSummary_GroupPhoto_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TaskMainPanel_C:OnChangeTaskTab(TaskTab)
  if self.FirstSelectTaskTab then
    self.FirstSelectTaskTab = false
  else
    _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_TaskTabIcon1_C:OnTouchEnded")
  end
  self.FirstSelectTaskParagraph = true
  local CurItemType = self.data:GetSelectTaskTabIndex()
  for i = 1, #self.TaskTabList do
    self.TaskTabList[i]:RemoveSelected(CurItemType)
  end
  self.data:SetSelectTaskTabIndex(TaskTab)
  self:PlayAnimation(self.Change_icon_picture_out)
  self:SelectTaskTabInfo(TaskTab)
  self:RefreshTitleInfo(TaskTab)
  self:PlayAnimation(self.Change_option)
end

function UMG_TaskMainPanel_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_TaskMainPanel_C:RefreshTitleInfo(taskTab)
  if taskTab == TaskEnum.TaskTab.All then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
    end
  elseif taskTab == TaskEnum.TaskTab.journey then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
    end
  elseif taskTab == TaskEnum.TaskTab.Legendary then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[3].subtitle)
    end
  elseif taskTab == TaskEnum.TaskTab.Gleanings and self.titleConf and self.titleConf.subtitle then
    self.Title1:SetSubtitle(self.titleConf.subtitle[4].subtitle)
  end
end

function UMG_TaskMainPanel_C:OnNotOpenParagraph(_IsHasParagraph)
  if _IsHasParagraph then
    self.TaskTypeScroll:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.TaskTypeScroll:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.RightSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.RightSwitcher:SetActiveWidgetIndex(3)
end

local function _TaskCompare(a, b)
  return a.ParagraphInfo.paragraph < b.ParagraphInfo.paragraph
end

local function _ParaCompare(a, b)
  if a.IsSeasonTask and not b.IsSeasonTask then
    return true
  elseif b.IsSeasonTask and not a.IsSeasonTask then
    return false
  elseif a.UnitConf and b.UnitConf then
    return a.UnitConf.id < b.UnitConf.id
  elseif a.UnitConf and b.ParagraphInfo then
    return a.UnitConf.id < b.ParagraphInfo.paragraph
  elseif a.ParagraphInfo and b.ParagraphInfo then
    return a.ParagraphInfo.paragraph < b.ParagraphInfo.paragraph
  end
end

function UMG_TaskMainPanel_C:OnOpenJourneyEnvelope()
  local BaseTaskList = self.data:GetBaseTaskList()
  self:HideTab()
  self:SetAllTabInfo()
  local CurItemType = self.data:GetSelectTaskTabIndex()
  self:RestsTaskTypeCanvas(CurItemType)
end

function UMG_TaskMainPanel_C:SelectTaskTabInfo(TaskTab)
  self.TypeSwitcher:SetActiveWidgetIndex(TaskTab)
  if TaskTab == TaskEnum.TaskTab.All then
    if self:IsHasParagraph() then
      if self.AllTabWidgetList and #self.AllTabWidgetList > 0 then
        self:AddAllTabWidget()
      else
        self:SetAllTabInfo()
      end
      self:SetTaskTabSelectIndex(TaskTab, self.AllTabWidgetList)
    else
      self.RightSwitcher:SetActiveWidgetIndex(3)
    end
  else
    self:RestsTabOperation(TaskTab, self.RestsTabWidgetList[TaskTab])
    self:SetTaskTabSelectIndex(TaskTab, self.RestsTabWidgetList[TaskTab])
    if TaskTab == TaskEnum.TaskTab.Gleanings then
      self:SetParagraphNum()
    end
  end
  self:RestsTaskTypeCanvas(TaskTab)
end

function UMG_TaskMainPanel_C:RestsTabOperation(TaskTab, TabWidgetList)
  if TabWidgetList and #TabWidgetList > 0 then
    self:AddRestsTabWidget(TabWidgetList)
  else
    self:SetRestsTabInfo(TaskTab, TabWidgetList)
  end
end

function UMG_TaskMainPanel_C:SetAllTabInfo()
  local BaseTaskList = self.data:GetBaseTaskList()
  for i, TaskList in ipairs(BaseTaskList) do
    if TaskList.AllParagraph and #TaskList.AllParagraph > 0 then
      table.sort(TaskList.AllParagraph, _TaskCompareAll)
      self.AllTypeCanvas[TaskList.PanelIndex]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:CreateAllTaskTabWidget(self.TaskTab, self.AllTypeList[TaskList.PanelIndex], TaskList, TaskList.PanelIndex)
    else
      self.AllTypeCanvas[TaskList.PanelIndex]:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_TaskMainPanel_C:RestsTaskTypeCanvas(TaskTab)
  for i, TaskTypeInfo in ipairs(self.AllTypeCanvas) do
    if TaskTab == TaskEnum.TaskTab.All then
      if self.AllTabWidgetList[i] and #self.AllTabWidgetList[i].TaskTabWidget:GetList() > 0 then
        self.AllTypeTitle[i]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        TaskTypeInfo:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self.AllTypeTitle[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
        TaskTypeInfo:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    elseif i == TaskTab then
      TaskTypeInfo:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      TaskTypeInfo:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_TaskMainPanel_C:SetRestsTabInfo(TaskTab, TabWidgetList)
  local BaseTaskList = self.data:GetBaseTaskList()
  if BaseTaskList[TaskTab] and BaseTaskList[TaskTab].UnitList then
    if BaseTaskList[TaskTab].UnitList[1].UnitConf then
      table.sort(BaseTaskList[TaskTab].UnitList, _ParaCompare)
    end
    if BaseTaskList[TaskTab].UnitList[1].ParagraphInfo then
      local unFinished = {}
      local finished = {}
      local journey = {}
      for i = 1, #BaseTaskList[TaskTab].UnitList do
        if 0 == BaseTaskList[TaskTab].UnitList[i].ParagraphInfo.Type then
          table.insert(unFinished, BaseTaskList[TaskTab].UnitList[i])
        elseif 1 == BaseTaskList[TaskTab].UnitList[i].ParagraphInfo.Type then
          table.insert(finished, BaseTaskList[TaskTab].UnitList[i])
        end
      end
      table.sort(unFinished, _TaskCompare)
      table.sort(finished, _TaskCompare)
      for i = 1, #unFinished do
        table.insert(journey, unFinished[i])
      end
      for i = 1, #finished do
        table.insert(journey, finished[i])
      end
      BaseTaskList[TaskTab].UnitList = journey
    end
    for i, Unit in ipairs(BaseTaskList[TaskTab].UnitList) do
      if Unit.ParagraphList then
        local unFinished = {}
        local finished = {}
        local tasklist = {}
        for i = 1, #Unit.ParagraphList do
          if 0 == Unit.ParagraphList[i].ParagraphInfo.Type then
            table.insert(unFinished, Unit.ParagraphList[i])
          elseif 1 == Unit.ParagraphList[i].ParagraphInfo.Type then
            table.insert(finished, Unit.ParagraphList[i])
          end
        end
        table.sort(unFinished, _TaskCompare)
        table.sort(finished, _TaskCompare)
        for i = 1, #unFinished do
          table.insert(tasklist, unFinished[i])
        end
        for i = 1, #finished do
          table.insert(tasklist, finished[i])
        end
        Unit.ParagraphList = tasklist
      end
      self:CreateRestsTaskTabWidget(self.TaskTab, self.RestsTypeList[TaskTab], Unit, TaskTab, TabWidgetList)
    end
  end
end

function UMG_TaskMainPanel_C:CreateAllTaskTabWidget(_TaskTab, TaskType, TaskList, Index)
  if TaskType:GetChildrenCount() >= 1 then
    if self.AllTabWidgetList[Index] then
      self.AllTabWidgetList[Index].TaskList = TaskList
      self.AllTabWidgetList[Index].TaskTabWidget:SetAllTabData(TaskList)
    end
    return
  end
  local TaskTabWidget = UE4.UWidgetBlueprintLibrary.Create(self, _TaskTab)
  if TaskTabWidget then
    local iconSlot = TaskType:AddChild(TaskTabWidget)
    TaskTabWidget:SetAllTabData(TaskList)
    self.AllTabWidgetList[Index] = {TaskTabWidget = TaskTabWidget, TaskList = TaskList}
    return TaskTabWidget
  end
end

function UMG_TaskMainPanel_C:CreateRestsTaskTabWidget(_TaskTab, TaskType, Unit, Index, TabWidgetList)
  local TaskTabWidget = UE4.UWidgetBlueprintLibrary.Create(self, _TaskTab)
  if TaskTabWidget then
    local iconSlot = TaskType:AddChild(TaskTabWidget)
    TaskTabWidget:SetRestsTabData(Unit)
    table.insert(TabWidgetList, {TaskTabWidget = TaskTabWidget, TaskList = Unit})
    return TaskTabWidget
  end
end

function UMG_TaskMainPanel_C:AddAllTabWidget()
  for i, AllTabWidget in pairs(self.AllTabWidgetList) do
    AllTabWidget.TaskTabWidget:SetAllTabData(self.AllTabWidgetList[i].TaskList)
  end
end

function UMG_TaskMainPanel_C:AddRestsTabWidget(TabWidgetList)
  for i, TabWidget in pairs(TabWidgetList) do
    TabWidget.TaskTabWidget:SetRestsTabData(TabWidgetList[i].TaskList)
  end
end

function UMG_TaskMainPanel_C:SetTaskTabSelectIndex(TaskTab, TabWidgetList)
  local IsHaveTrackTask = false
  local TaskTabIndex = 0
  local ParagraphIndex = 0
  local EphemeralParagraphIndex = 0
  for i, TabWidget in pairs(TabWidgetList) do
    IsHaveTrackTask, EphemeralParagraphIndex = TabWidget.TaskTabWidget:SetSelectParagraph(true, self.TaskId, self.data:GetOpenParagraph(), true)
    if IsHaveTrackTask then
      TaskTabIndex = i
      ParagraphIndex = EphemeralParagraphIndex
      break
    else
      TaskTabIndex = 0
      ParagraphIndex = EphemeralParagraphIndex
    end
  end
  if 0 == TaskTabIndex then
    TabWidgetList[1].TaskTabWidget:SelectFirstIndex()
  end
  self:DelayFrames(2, function()
    local TaskTabOffset = 0
    local TitleOffset = 0
    local ParagraphOffset = 0
    local Offset = 0
    if TaskTab == TaskEnum.TaskTab.All then
      for i, TaskType in ipairs(self.AllTypeList) do
        if i < TaskTabIndex then
          local ViewportSize = UE4.USlateBlueprintLibrary.GetLocalSize(TaskType:GetCachedGeometry())
          TaskTabOffset = TaskTabOffset + ViewportSize.Y
        end
      end
      local TaskTypeTitleSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.AllTypeTitle[1]:GetCachedGeometry())
      TitleOffset = (TaskTabIndex - 1) * TaskTypeTitleSize.Y
    else
      for i, TabWidget in pairs(TabWidgetList) do
        if i < TaskTabIndex then
          local ViewportSizeY = TabWidget.TaskTabWidget:GetSizeY()
          TaskTabOffset = TaskTabOffset + ViewportSizeY
        end
        if i == TaskTabIndex then
          local TitleSizeY = TabWidget.TaskTabWidget:GetTitleSizeY()
          TaskTabOffset = TaskTabOffset + TitleSizeY
        end
      end
    end
    ParagraphOffset = 0
    local itemHeight = 0
    if TabWidgetList and TabWidgetList[1] and TabWidgetList[1].TaskTabWidget then
      itemHeight = TabWidgetList[1].TaskTabWidget:GetItemSizeY() * (ParagraphIndex - 2)
    end
    ParagraphOffset = math.max(0, itemHeight)
    Offset = TaskTabOffset + ParagraphOffset + TitleOffset
    self.TaskTypeScroll:SetScrollOffset(Offset)
  end)
end

function UMG_TaskMainPanel_C:ClearAllWidget()
  for i, TaskType in pairs(self.AllTypeList) do
    TaskType:ClearChildren()
  end
end

function UMG_TaskMainPanel_C:ClearRestsSelect(ParagraphInfo)
  local CurItemType = self.data:GetSelectTaskTabIndex()
  local TabWidgetList
  if CurItemType == TaskEnum.TaskTab.All then
    TabWidgetList = self.AllTabWidgetList
  else
    TabWidgetList = self.RestsTabWidgetList[CurItemType]
  end
  for i, TabWidget in pairs(TabWidgetList) do
    TabWidget.TaskTabWidget:GetCurrentSelectParagraph(ParagraphInfo)
  end
end

function UMG_TaskMainPanel_C:OnSelectTaskParagraph(Task_Info, ParagraphInfo, uiData)
  if self.FirstSelectTaskParagraph then
    self.FirstSelectTaskParagraph = false
  else
    _G.NRCAudioManager:PlaySound2DAuto(40007005, "UMG_Friend_Item_C:StartFriendVisit")
  end
  self:SetExpireTime(Task_Info.id)
  self:UpdateTaskSummaryGroupPhoto(uiData)
  self.RightSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  Log.Debug(ParagraphInfo and ParagraphInfo.paragraph, Task_Info and Task_Info.id, "UMG_TaskMainPanel_C:OnSelectTaskParagraph")
  self.ParagraphInfo = ParagraphInfo
  Log.Dump(Task_Info, 3, "UMG_TaskMainPanel_C:OnSelectTaskParagraph")
  local ParagraphConf = _G.DataConfigManager:GetParagraphConf(ParagraphInfo and ParagraphInfo.paragraph)
  if Task_Info then
    self:PlayEnVeLopeType()
    self.Task_Info = Task_Info
    local TaskConf = _G.DataConfigManager:GetTaskConf(Task_Info.id)
    self.TaskConf = TaskConf
    if not self.OldTaskInfo or self.OldTaskInfo.task_class ~= TaskConf.task_class then
    end
    self:PlayAnimation(self.Change_icon_picture)
    if TaskConf.task_class == Enum.TaskClassType.TCT_JOURNEY then
      self.RightSwitcher:SetActiveWidgetIndex(0)
      self.chapterBg:SetPath(ParagraphConf.paragraph_background)
      self.MainTitleText:SetText(ParagraphConf.title)
      self:SetTaskSource(TaskConf.belong_place, self.MainNameText, self.NRCImage_249)
      self:SetCanvasHide(Task_Info, ParagraphInfo, uiData, self.GetCanvas_1, self.GetText_1, TaskEnum.TaskTab.journey)
      self.MainText:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.MainTextFinish:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if Task_Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE or self:IsDoneParaGraph(TaskEnum.TaskTab.journey, ParagraphInfo.paragraph) then
        self.MainScrollView:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.MapBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.TraceBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.TraceText:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.MainTextFinish:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.MainTextFinish:SetText(string.format("                 %s", ParagraphConf.description_new))
        self:SetQiYinRedPoint(0)
        self.QiyinCanvas_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.MainScrollView:SetVisibility(UE4.ESlateVisibility.Visible)
        self:SetTaskGoalDetail(Task_Info, TaskConf, self.MainScrollView)
        self:SetTraceInfo(TaskConf, self.TraceText, self.TraceBtn, self.MapBtn)
        self:SetTraceBtnText(Task_Info, self.TraceBtn)
        self.MainText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.MainText:SetText(string.format("                 %s", TaskConf.task_des))
        if TaskConf.task_system_item and 0 ~= TaskConf.task_system_item then
          self.QiyinCanvas_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          if TaskConf.task_system_item and 0 ~= TaskConf.task_system_item then
            local BagItemConf = _G.DataConfigManager:GetBagItemConf(TaskConf.task_system_item)
            self.QiyinIcon_2:SetPath(BagItemConf.big_icon)
            self.QiyinText_2:SetText(BagItemConf.name)
          else
          end
          self:SetQiYinRedPoint(TaskConf.task_system_item)
        else
          self:SetQiYinRedPoint(0)
          self.QiyinCanvas_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
    elseif TaskConf.task_class == Enum.TaskClassType.TCT_MAIN then
      self.RightSwitcher:SetActiveWidgetIndex(1)
      self.EntrustTtileText:SetText(ParagraphConf.title)
      self:SetTaskSource(TaskConf.belong_place, self.EntrustNameText, self.NRCImage_20)
      self:SetCanvasHide(Task_Info, ParagraphInfo, uiData, self.GetCanvas_2, self.GetText_2, TaskEnum.TaskTab.Legendary)
      if Task_Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE or self:IsDoneParaGraph(TaskEnum.TaskTab.Legendary, ParagraphInfo.paragraph) then
        self.EntrustScrollView:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.EntrustContentText:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.EntrustSpacer1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.EntrustTextFinish:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.EntrustTextFinish:SetText(ParagraphConf.description_new)
        self:SetQiYinRedPoint(0)
        self.QiyinCanvas_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.EntrustContentText:SetText(TaskConf.task_des)
        self.EntrustSpacer1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.EntrustContentText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.EntrustScrollView:SetVisibility(UE4.ESlateVisibility.Visible)
        self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.EntrustTextFinish:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self:SetTaskGoalDetail(Task_Info, TaskConf, self.EntrustScrollView)
        self:SetTraceInfo(TaskConf, self.TraceText_1, self.TraceBtn2, self.MapBtn2)
        self:SetTraceBtnText(Task_Info, self.TraceBtn2)
        self:SetLegendaryRewardInfo(TaskConf, ParagraphInfo)
        if TaskConf.task_system_item and 0 ~= TaskConf.task_system_item then
          self.QiyinCanvas_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          if TaskConf.task_system_item and 0 ~= TaskConf.task_system_item then
            local BagItemConf = _G.DataConfigManager:GetBagItemConf(TaskConf.task_system_item)
            self.QiyinIcon_1:SetPath(BagItemConf.big_icon)
            self.QiyinText_1:SetText(BagItemConf.name)
          else
          end
          self:SetQiYinRedPoint(TaskConf.task_system_item)
        else
          self:SetQiYinRedPoint(0)
          self.QiyinCanvas_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
    elseif TaskConf.task_class == Enum.TaskClassType.TCT_SUB then
      self:SetCanvasHide(Task_Info, ParagraphInfo, uiData, self.GetCanvas_3, self.GetText_3, TaskEnum.TaskTab.Gleanings)
      self.RightSwitcher:SetActiveWidgetIndex(2)
      self.BranchTitleText:SetText(ParagraphConf.title)
      self:SetTaskSource(TaskConf.belong_place, self.BranchNameText, self.NRCImage_4)
      local pos = self.QiyinIcon.Slot:GetPosition()
      if Task_Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE or self:IsDoneParaGraph(TaskEnum.TaskTab.Gleanings, ParagraphInfo.paragraph) then
        self.BranchSpacer1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.CanvasPanel_43:SetVisibility(UE4.ESlateVisibility.Collapsed)
        if TaskConf.task_system_item and 0 ~= TaskConf.task_system_item then
          pos.x = 206
          pos.y = 34
          self.QiyinCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.QiyinEquip:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.QiyinNotEquip:SetVisibility(UE4.ESlateVisibility.Collapsed)
          local BagItemConf = _G.DataConfigManager:GetBagItemConf(TaskConf.task_system_item)
          self.QiyinIcon:SetPath(BagItemConf.big_icon)
          self.QiyinText:SetText(BagItemConf.name)
          self.QiyinIcon_new:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self:SetQiYinRedPoint(TaskConf.task_system_item)
        else
          self:SetQiYinRedPoint(0)
          pos.x = 176
          pos.y = 24
          self.QiyinCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
        local Content = _G.NRCModeManager:DoCmd(TaskModuleCmd.GetParagraphContent, {})
        if Content and #Content > 0 then
          self.BranchScrollView:SetVisibility(UE4.ESlateVisibility.Visible)
          self.BranchSpacer2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          self.BranchScrollView:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.BranchSpacer2:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
        self.BranchContentText:SetText(TaskConf.rewrite)
        self.BranchScrollView:InitList(Content)
        self.BranchContentText1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.BranchContentText1:SetText(ParagraphConf.description_new)
      else
        self.BranchSpacer1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.CanvasPanel_43:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.BranchContentText1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.BranchScrollView:SetVisibility(UE4.ESlateVisibility.Visible)
        self.BranchContentText:SetText(TaskConf.task_des)
        self:SetTaskGoalDetail(Task_Info, TaskConf, self.BranchScrollView)
        self:SetTraceInfo(TaskConf, self.TraceText_2, self.TraceBtn1, self.MapBtn1)
        self:SetTraceBtnText(Task_Info, self.TraceBtn1)
        if TaskConf.task_system_item and 0 ~= TaskConf.task_system_item then
          self.QiyinCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.QiyinEquip:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.QiyinNotEquip:SetVisibility(UE4.ESlateVisibility.Collapsed)
          local BagItemConf = _G.DataConfigManager:GetBagItemConf(TaskConf.task_system_item)
          self.QiyinIcon:SetPath(BagItemConf.big_icon)
          self.QiyinText:SetText(BagItemConf.name)
          self.QiyinIcon_new:SetVisibility(UE4.ESlateVisibility.Collapsed)
          pos.x = 206
          pos.y = 34
          self:SetQiYinRedPoint(TaskConf.task_system_item)
        else
          self:SetLacquerInfo(ParagraphInfo)
          pos.x = 176
          pos.y = 24
          self:SetQiYinRedPoint(0)
        end
        self:SetGleaningsRewardInfo()
      end
      self.QiyinIcon.Slot:SetPosition(pos)
    end
    if ShowID then
      local Title = string.format("%s-%d-%d", ParagraphConf.title, ParagraphConf.id, TaskConf.id)
      self.MainTitleText:SetText(Title)
      self.BranchTitleText:SetText(Title)
      self.EntrustTtileText:SetText(Title)
    end
    self:PlayAnimation(self.Change_icon)
    self.OldTaskInfo = TaskConf
  end
end

function UMG_TaskMainPanel_C:SetQiYinRedPoint(ItemId)
  if ItemId and ItemId > 0 then
    local TaskItem = _G.DataConfigManager:GetAllByName("TASK_ITEM")
    local type
    for i = 1, #TaskItem do
      if TaskItem[i].bag_item_id == ItemId then
        type = TaskItem[i].task_type
        break
      end
    end
    if 170018 == ItemId or type == Enum.TaleTaskType.TALE_MAGIC_BOOK then
      self.QiYiRedPoint_1:SetupKey(2)
      self.QiYiRedPoint:SetupKey(2)
      self.QiYiRedPoint_2:SetupKey(2)
    else
      self.QiYiRedPoint_1:SetupKey(246, {type})
      self.QiYiRedPoint:SetupKey(246, {type})
      self.QiYiRedPoint_2:SetupKey(246, {type})
    end
  else
    self.QiYiRedPoint:SetupKey(0)
    self.QiYiRedPoint_1:SetupKey(0)
    self.QiYiRedPoint_2:SetupKey(0)
  end
end

function UMG_TaskMainPanel_C:SetParagraphNum()
  local BaseTaskList = self.data:GetBaseTaskList()
  local Num = #BaseTaskList[TaskEnum.TaskTab.Gleanings].AllParagraph
  local MaxNum = _G.DataConfigManager:GetTaskGlobalConfig("sub_task_ongoing_num_max").num
  if Num > 0 then
    self.GleaningsNumText:SetText(string.format("%d/%d", Num, MaxNum))
  else
  end
end

function UMG_TaskMainPanel_C:SetCanvasHide(Task_Info, ParagraphInfo, uiData, FinishCanvas, GetText, TaskTab)
  if not uiData and (Task_Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE or self:IsDoneParaGraph(TaskTab, ParagraphInfo.paragraph)) then
    FinishCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local ban_time = os.date("%Y.%m.%d", ParagraphInfo.time)
    GetText:SetText(ban_time)
  else
    FinishCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TaskMainPanel_C:SetTaskGoalDetail(Task_Info, TaskConf, ScrollView)
  local TaskConditionList = {}
  for i, Task in ipairs(TaskConf.task_condition) do
    local SortIndex = i
    local Data = Task_Info.task_target_list and Task_Info.task_target_list[i] or 0
    if Data >= Task.count then
      SortIndex = 999 + i
    end
    table.insert(TaskConditionList, {
      Condition = Task,
      Data = Data,
      SortIndex = SortIndex,
      IsShowExtraTask = false,
      pos = i
    })
    if TaskConf.task_class == Enum.TaskClassType.TCT_SUB then
      local IsShowExTraTask = _G.NRCModeManager:DoCmd(TaskModuleCmd.ShowExtraTaskByTokenInfo)
      if IsShowExTraTask then
        table.insert(TaskConditionList, {IsShowExtraTask = true, pos = i})
      end
    end
  end
  table.sort(TaskConditionList, function(a, b)
    return a.SortIndex < b.SortIndex
  end)
  self.TaskConditionList = TaskConditionList
  ScrollView:InitList(TaskConditionList)
end

function UMG_TaskMainPanel_C:SetLegendaryRewardInfo(TaskConf, ParagraphInfo)
  local RewardItemList = {}
  local Reward
  local ParagraphConf = _G.DataConfigManager:GetParagraphConf(ParagraphInfo.paragraph)
  if ParagraphConf.Reward and 0 ~= ParagraphConf.Reward then
    Reward = ParagraphConf.Reward
  elseif TaskConf.Reward and 0 ~= TaskConf.Reward then
    Reward = TaskConf.Reward
  end
  if not Reward then
    self.RewardList2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_22:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCText_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  self.RewardList2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.NRCImage_22:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.NRCText_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local RewardConf = _G.DataConfigManager:GetRewardConf(Reward)
  local RewardItem = RewardConf.RewardItem
  for i, RewardData in ipairs(RewardItem) do
    if (RewardData.Type ~= _G.Enum.GoodsType.GT_CARD_ICON or RewardData.Type ~= _G.Enum.GoodsType.GT_CARD_SKIN or RewardData.Type ~= _G.Enum.GoodsType.GT_CARD_LABEL) and RewardData.Type ~= _G.Enum.GoodsType.GT_REWARD then
      table.insert(RewardItemList, {
        RewardItem = RewardData,
        RewardType = TaskEnum.AddOrRemoveTaskReward.Null,
        Count = RewardData.Count,
        TokenType = nil
      })
    end
  end
  local rewardsTable = {}
  for k, v in ipairs(RewardItemList) do
    local rewards = _G.NRCCommonItemIconData()
    rewards.itemType = v.RewardItem.Type
    rewards.itemId = v.RewardItem.Id
    rewards.itemNum = v.RewardItem.Count
    rewards.bShowNum = true
    rewards.bShowTip = true
    if v.TokenType and v.TokenType == _G.Enum.TokenRewardType.TOKEN_MULTI_REWARD then
      rewards.bShowTaskTag = true
    end
    table.insert(rewardsTable, rewards)
  end
  self.RewardList2:InitGridView(rewardsTable)
end

function UMG_TaskMainPanel_C:SetGleaningsRewardInfo(IsTokenChange, IsEquipment)
  local RewardId
  if self.ParagraphInfo and self.TaskConf then
    local ParagraphConf = _G.DataConfigManager:GetParagraphConf(self.ParagraphInfo.paragraph)
    if ParagraphConf.Reward and 0 ~= ParagraphConf.Reward then
      RewardId = ParagraphConf.Reward
    elseif self.TaskConf.Reward and 0 ~= self.TaskConf.Reward then
      RewardId = self.TaskConf.Reward
    end
  end
  if not RewardId then
    self.NRCImage_108:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCText_68:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RewardList3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  Log.Debug(RewardId, "UMG_Task_Gleanings_C:UpdateRewardList")
  self.RewardList = {}
  if RewardId and 0 ~= RewardId then
    local RewardConf = _G.DataConfigManager:GetRewardConf(RewardId)
    local RewardItem = RewardConf.RewardItem
    for i, RewardData in ipairs(RewardItem) do
      if (RewardData.Type ~= _G.Enum.GoodsType.GT_CARD_ICON or RewardData.Type ~= _G.Enum.GoodsType.GT_CARD_SKIN or RewardData.Type ~= _G.Enum.GoodsType.GT_CARD_LABEL) and RewardData.Type ~= _G.Enum.GoodsType.GT_REWARD then
        table.insert(self.RewardList, {
          RewardItem = RewardData,
          RewardType = TaskEnum.AddOrRemoveTaskReward.Null,
          Count = RewardData.Count,
          TokenType = nil
        })
      end
    end
  end
  local CurrentSelectParagraphToken = _G.NRCModeManager:DoCmd(TaskModuleCmd.GetCurrentSelectParagraphToken)
  if IsTokenChange then
    if CurrentSelectParagraphToken and CurrentSelectParagraphToken.task_token_info and CurrentSelectParagraphToken.task_token_info[1].task_token_id then
      local ParagraphStarTask = _G.NRCModeManager:DoCmd(TaskModuleCmd.GetParagraphStarTask)
      self:AddOrRemoveReward(IsEquipment, CurrentSelectParagraphToken.task_token_info[1].task_token_id, true)
    else
      self:InitRewardList3()
    end
  elseif CurrentSelectParagraphToken and CurrentSelectParagraphToken.task_token_info and CurrentSelectParagraphToken.task_token_info[1].task_token_id then
    local ParagraphStarTask = _G.NRCModeManager:DoCmd(TaskModuleCmd.GetParagraphStarTask)
    self:AddOrRemoveReward(true, CurrentSelectParagraphToken.task_token_info[1].task_token_id, false)
  else
    self:InitRewardList3()
  end
end

function UMG_TaskMainPanel_C:AddOrRemoveReward(IsEquipment, TokenId, IsPlayAnim)
  local TaskTokenConf = _G.DataConfigManager:GetTaskTokenConf(TokenId)
  local RewardItem = TaskTokenConf.token_reward
  local IsPrize = self.RewardList[1].IsPrize
  local RewardList = {}
  if IsEquipment then
    for v = #RewardItem, 1, -1 do
      if (RewardItem[v].goods_type ~= _G.Enum.GoodsType.GT_CARD_ICON or RewardItem[v].goods_type ~= _G.Enum.GoodsType.GT_CARD_SKIN or RewardItem[v].goods_type ~= _G.Enum.GoodsType.GT_CARD_LABEL) and RewardItem[v].goods_type ~= _G.Enum.GoodsType.GT_REWARD then
        if RewardItem[v].token_reward_type == _G.Enum.TokenRewardType.TOKEN_MULTI_REWARD then
          self:FindRewardAndChange(IsEquipment, RewardItem[v].goods_type, RewardItem[v].token_reward_param, RewardItem[v].goods_id)
        else
          RewardList.Type = RewardItem[v].goods_type
          RewardList.Id = RewardItem[v].goods_id
          table.insert(self.RewardList, {
            RewardItem = RewardList,
            IsPrize = IsPrize,
            Count = RewardItem[v].token_reward_param,
            TokenType = _G.Enum.TokenRewardType.TOKEN_ADD_REWARD
          })
        end
      end
    end
    if IsPlayAnim then
    end
  else
    for v = #RewardItem, 1, -1 do
      if RewardItem[v].token_reward_type == _G.Enum.TokenRewardType.TOKEN_MULTI_REWARD then
        self:FindRewardAndChange(IsEquipment, RewardItem[v].goods_type, RewardItem[v].token_reward_param, RewardItem[v].goods_id)
      elseif RewardItem[v].token_reward_type == _G.Enum.TokenRewardType.TOKEN_ADD_REWARD then
        for i, Reward in ipairs(self.RewardList) do
          if Reward.RewardItem.Type ~= Enum.GoodsType.GT_VITEM and RewardItem[v].goods_id == Reward.RewardItem.Id then
            table.remove(self.RewardList, i)
          end
        end
      end
    end
  end
  self:InitRewardList3()
end

function UMG_TaskMainPanel_C:InitRewardList3()
  if self.RewardList and #self.RewardList > 0 then
    local rewardsTable = {}
    for k, v in ipairs(self.RewardList) do
      local rewards = _G.NRCCommonItemIconData()
      rewards.itemType = v.RewardItem.Type
      rewards.itemId = v.RewardItem.Id
      rewards.itemNum = v.RewardItem.Count
      rewards.bShowNum = true
      rewards.bShowTip = true
      if v.TokenType and v.TokenType == _G.Enum.TokenRewardType.TOKEN_MULTI_REWARD then
        rewards.bShowTaskTag = true
      end
      table.insert(rewardsTable, rewards)
    end
    Log.Dump(rewardsTable, 3, "UMG_TaskMainPanel_C:InitRewardList3")
    self.RewardList3:InitList(rewardsTable)
    self.NRCImage_108:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCText_68:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RewardList3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCImage_108:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCText_68:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RewardList3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TaskMainPanel_C:FindRewardAndChange(IsEquipment, GoodsType, reward_param, goods_id)
  for i, Reward in ipairs(self.RewardList) do
    if Reward.RewardItem.Type == GoodsType and Reward.RewardItem.Id == goods_id then
      if IsEquipment then
        if not Reward.TokenType then
          Reward.Count = Reward.Count * reward_param
          Reward.TokenType = _G.Enum.TokenRewardType.TOKEN_MULTI_REWARD
        end
      else
        Reward.TokenType = nil
      end
    end
  end
end

function UMG_TaskMainPanel_C:SetRewardType(_IsAdd)
  for i, Reward in ipairs(self.RewardList) do
    if _IsAdd then
      Reward.RewardType = TaskEnum.AddOrRemoveTaskReward.Add
    else
      Reward.RewardType = TaskEnum.AddOrRemoveTaskReward.Remove
    end
  end
end

function UMG_TaskMainPanel_C:AddOrRemoveTask(IsEquipment)
  local OpenTask = self.data:GetOpenTask()
  local TaskConf = _G.DataConfigManager:GetTaskConf(OpenTask.id)
  if TaskConf.task_class ~= Enum.TaskClassType.TCT_SUB then
    return
  end
  local IsShowExTraTask = self.data:ShowExtraTaskByTokenInfo()
  if IsEquipment then
    if IsShowExTraTask then
      table.insert(self.TaskConditionList, {IsShowExtraTask = true, pos = 1})
    end
  elseif IsShowExTraTask then
    table.remove(self.TaskConditionList, #self.TaskConditionList)
  end
  self.BranchScrollView:InitList(self.TaskConditionList)
end

function UMG_TaskMainPanel_C:SetTaskSource(belong_place, SourceText, SourceIcon)
  if not belong_place or "" == belong_place then
    SourceText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    SourceIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    SourceText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    SourceIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    SourceText:SetText(belong_place)
  end
end

function UMG_TaskMainPanel_C:SetLacquerInfo(ParagraphInfo)
  local LacquerIsUnLock = self.data:GetLacquerIsUnLockByParagraph(ParagraphInfo.paragraph)
  if LacquerIsUnLock then
    local CurrentSelectParagraphToken = self.data:GetCurrentSelectParagraphToken()
    self:OnSetTaskToken(CurrentSelectParagraphToken and CurrentSelectParagraphToken.task_token_info and CurrentSelectParagraphToken.task_token_info[1].task_token_id)
    self.QiyinCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.QiyinCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TaskMainPanel_C:OnSetTaskToken(_task_token_id)
  if _task_token_id then
    self.QiyinEquip:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.QiyinNotEquip:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local TaskTokenConf = _G.DataConfigManager:GetTaskTokenConf(_task_token_id)
    self.QiyinIcon:SetPath(TaskTokenConf.token__source)
    self.QiyinText:SetText(TaskTokenConf.name)
  else
    self.QiyinEquip:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.QiyinNotEquip:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.QiyinIcon_new:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_TaskMainPanel_C:OnSubTaskTokenEvent(IsEquipment, task_token_id, TokenUseTYpe)
  Log.Debug(task_token_id, TokenUseTYpe, "UMG_TaskMainPanel_C:OnSubTaskTokenEvent")
  self:SetGleaningsRewardInfo(true, IsEquipment)
  self:AddOrRemoveTask(IsEquipment)
  if TokenUseTYpe and TokenUseTYpe == TaskEnum.ToKenUseType.Equipment then
    self:PlayAnimation(self.shiyi_begin)
  elseif TokenUseTYpe and TokenUseTYpe == TaskEnum.ToKenUseType.DisCharge then
    self.QiyinNotEquip:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.shiyi_out)
    self.data:SetCurrentSelectParagraphToken(nil)
    return
  elseif TokenUseTYpe and TokenUseTYpe == TaskEnum.ToKenUseType.Replace then
    local TaskTokenConf = _G.DataConfigManager:GetTaskTokenConf(task_token_id)
    self.QiyinIcon_new:SetPath(TaskTokenConf.token__source)
    self.QiyinText:SetText(TaskTokenConf.name)
    self.QiyinIcon_new:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.shiyi_change)
    return
  end
  self:OnSetTaskToken(task_token_id)
end

function UMG_TaskMainPanel_C:OnLacquerBtn()
  local Task_Info = self.data:GetOpenTask()
  local TaskConf = _G.DataConfigManager:GetTaskConf(Task_Info.id)
  if TaskConf.task_system_item and TaskConf.task_system_cmd then
    local text = TaskConf.task_system_cmd
    _G.NRCModuleManager:DoCmdWithArgs(text)
  else
    _G.NRCModuleManager:DoCmd(TaskModuleCmd.OpenMagicStampPanel, TaskEnum.OpenToKenType.operation, TaskEnum.MagicStampTabType.Lacquer)
  end
end

function UMG_TaskMainPanel_C:OnLacquerBtn1()
  _G.NRCAudioManager:PlaySound2DAuto(1010, "UMG_TaskMainPanel_C:OnLacquerBtn1")
  local Task_Info = self.data:GetOpenTask()
  local TaskConf = _G.DataConfigManager:GetTaskConf(Task_Info.id)
  if TaskConf.task_system_item and TaskConf.task_system_cmd then
    local text = TaskConf.task_system_cmd
    _G.NRCModuleManager:DoCmdWithArgs(text)
  end
end

function UMG_TaskMainPanel_C:OnClickCollectBtn()
  if self.data:GetIsOpenTips() then
    return
  end
  NRCModuleManager:DoCmd(BagModuleCmd.OpenNPCRoster, self.rsp.data.npcs)
  _G.NRCAudioManager:PlaySound2DAuto(41400009, "UMG_MagicBook_C:OnPrePageBtnClick")
  NRCProfilerLog:NRCClickBtn(true, "Roster")
end

function UMG_TaskMainPanel_C:OnClickBtnPressed()
  self.CollectTab:PlayAnimation(self.CollectTab.Press)
end

function UMG_TaskMainPanel_C:OnClickBtnReleased()
  self.CollectTab:PlayAnimation(self.CollectTab.Up)
end

function UMG_TaskMainPanel_C:OnClickBtnClose(_IsCloseCompass)
  Log.Debug(self.IsCanOnClick, "UMG_TaskMainPanel_C:OnClickBtnClose")
  if self.IsCanOnClick == false then
    return
  end
  local mappingContext = self:GetInputMappingContext("IMC_TaskUI")
  if mappingContext then
    mappingContext:UnBindAction("IA_CloseTaskUI")
    mappingContext:UnBindAction("IA_CloseTaskQuick")
  end
  self.IsCanOnClick = false
  self.IsCloseCompass = _IsCloseCompass
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1008, "UMG_Main_Task_C:OnClickBtnClose")
  self:OnClose()
end

function UMG_TaskMainPanel_C:OpenMapPanel(Param)
  if not _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.OpenWorldMap, Param) then
    return
  end
end

function UMG_TaskMainPanel_C:OnAnimationFinished(Anim)
  if Anim == self.Open then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
    self.IsCanOnClick = true
  elseif Anim == self.Close then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
    if self.IsCloseCompass then
      _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnClickTaskTrackToWorldFast)
    end
    self:DoClose()
  elseif Anim == self.shiyi_change then
    local CurrentSelectParagraphToken = self.data:GetCurrentSelectParagraphToken()
    if CurrentSelectParagraphToken and CurrentSelectParagraphToken.task_token_info and CurrentSelectParagraphToken.task_token_info[1].task_token_id then
      local TaskTokenConf = _G.DataConfigManager:GetTaskTokenConf(CurrentSelectParagraphToken.task_token_info[1].task_token_id)
      self.QiyinIcon:SetPath(TaskTokenConf.token__source)
    end
  elseif Anim == self.Change_icon_picture_out then
  end
end

function UMG_TaskMainPanel_C:OnClickMapBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TaskMainPanel_C:OnClickMapBtn")
  local Task_Info = self.data:GetOpenTask()
  if Task_Info then
    if _G.BigMapModuleCmd then
      self:OpenMapPanel({
        TaskId = Task_Info.id,
        IsOpenRightPanel = true,
        WorldFast = true
      })
    else
      Log.Error("\230\137\190\228\184\141\229\136\176BigMapModuleCmd")
    end
  else
    Log.Error("\230\178\161\230\156\137\232\191\155\232\161\140\228\184\173\231\154\132\228\187\187\229\138\161")
  end
end

function UMG_TaskMainPanel_C:OnSwitcherRightSwitcher(SwitcherIndex)
  self.RightSwitcher:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_TaskMainPanel_C:SetTraceInfo(TaskConf, TraceText, TraceBtn, MapBtn)
  local IsVisitState = _G.DataModelMgr.PlayerDataModel:IsVisitState()
  local CanVisitTrace = true
  if IsVisitState and TaskConf then
    if TaskConf.peer_available then
      CanVisitTrace = true
    elseif _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
      CanVisitTrace = true
    else
      CanVisitTrace = false
    end
  end
  local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_DIA_UNTRACK_TASK)
  if Flags then
    TraceBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    MapBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    TraceText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if not CanVisitTrace then
    TraceText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    TraceText:SetText(LuaText.TASK_INTERFACE_PEER_DISAVAILABLE)
    TraceBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    MapBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  TraceText:SetText(LuaText.clue_text)
  if TaskConf and TaskConf.is_break_task then
    TraceText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    TraceBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    MapBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    TraceText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    TraceBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_TaskMainPanel_C:SetTraceBtnText(Task_Info, TraceBtn)
  if not Task_Info or not TraceBtn then
    return
  end
  local TrackingTask = _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.GetTrackTask)
  local TrackingTaskID = TrackingTask and TrackingTask.Info.id or 0
  self.isTracking = TrackingTaskID == Task_Info.id
  TraceBtn:SetBtnText(self.isTracking and LuaText.umg_npcinfo_3 or LuaText.umg_npcinfo_1)
end

function UMG_TaskMainPanel_C:OnTrackBtn()
  if self.isTracking then
    _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Friend_Item_C:StartFriendVisit")
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401005, "UMG_Friend_Item_C:StartFriendVisit")
  end
  _G.NRCModeManager:DoCmd(_G.TaskModuleCmd.OnClickTraceBtn, not self.isTracking)
  self:UpdateTrackBtn()
end

function UMG_TaskMainPanel_C:UpdateTrackBtn()
  local Task_Info = self.data:GetOpenTask()
  if Task_Info then
    local TaskConf = _G.DataConfigManager:GetTaskConf(Task_Info.id)
    if TaskConf.task_class == Enum.TaskClassType.TCT_JOURNEY then
      self:SetTraceBtnText(Task_Info, self.TraceBtn)
    elseif TaskConf.task_class == Enum.TaskClassType.TCT_MAIN then
      self:SetTraceBtnText(Task_Info, self.TraceBtn2)
    elseif TaskConf.task_class == Enum.TaskClassType.TCT_SUB then
      self:SetTraceBtnText(Task_Info, self.TraceBtn1)
    end
  else
    Log.Error("\230\178\161\230\156\137\230\137\147\229\188\128\231\154\132\228\187\187\229\138\161,\230\159\165\231\156\139\229\142\159\229\155\160")
  end
end

function UMG_TaskMainPanel_C:SetTrackTaskStateFromMap(rspId)
  local CurItemType = self.data:GetSelectTaskTabIndex()
  local TabWidgetList
  if CurItemType == TaskEnum.TaskTab.All then
    TabWidgetList = self.AllTabWidgetList
  else
    TabWidgetList = self.RestsTabWidgetList[CurItemType]
  end
  for i, TabWidget in pairs(TabWidgetList) do
    TabWidget.TaskTabWidget:SetTrackTaskStateFromMap(rspId)
  end
end

function UMG_TaskMainPanel_C:SetTrackTaskState()
  local CurItemType = self.data:GetSelectTaskTabIndex()
  local TabWidgetList
  if CurItemType == TaskEnum.TaskTab.All then
    TabWidgetList = self.AllTabWidgetList
  else
    TabWidgetList = self.RestsTabWidgetList[CurItemType]
  end
  for i, TabWidget in pairs(TabWidgetList) do
    TabWidget.TaskTabWidget:SetTrackTaskState()
  end
end

function UMG_TaskMainPanel_C:CheckCanOpenNPC()
  local req = _G.ProtoMessage:newZoneMageBookQueryReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_MAGE_BOOK_QUERY_REQ, req, self, self.OpenNPCRsp)
end

local function compare(a, b)
  return a.id < b.id
end

function UMG_TaskMainPanel_C:OpenNPCRsp(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.data.enabled == true then
    self.rsp = rsp
    self.CollectTab:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self:CheckNPCRosterHasRedPoint(rsp.data.npcs) then
      self.RosterRedPoint:SetupKey(242)
    end
    return
  end
  self.CollectTab:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_TaskMainPanel_C:CheckNPCRosterHasRedPoint(NPCDataList)
  local ValidNPCDataList = {}
  for i, NPCData in ipairs(NPCDataList) do
    if NPCData.unlocked == true then
      table.insert(ValidNPCDataList, NPCData)
    end
  end
  table.sort(ValidNPCDataList, compare)
  self.ValidNPCDataList = ValidNPCDataList
  local RedPointData = _G.NRCModuleManager:DoCmd(RedPointModuleCmd.GetRedPointSplitPointDataByKeyAndReason, 241, Enum.RedPointReason.RPR_MAGE_BOOK)
  local hasFindRedPoint = false
  for i, data in ipairs(RedPointData) do
    local npcID = tonumber(data[1])
    for j, npcData in ipairs(self.ValidNPCDataList) do
      if npcData.id == npcID then
        hasFindRedPoint = true
        break
      end
    end
  end
  return hasFindRedPoint
end

return UMG_TaskMainPanel_C
