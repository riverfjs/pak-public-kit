local BattlePassModuleEvent = require("NewRoco.Modules.System.BattlePass.BattlePassModuleEvent")
local UMG_Pass_Activity_C = _G.NRCPanelBase:Extend("UMG_Pass_Activity_C")

function UMG_Pass_Activity_C:OnDeactive()
end

function UMG_Pass_Activity_C:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_Activity_C", self, BattlePassModuleEvent.SelectBattlePassWeekIndex, self.SelectWeekTable)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_Activity_C", self, BattlePassModuleEvent.UpdateActivityTaskDatas, self.RefreshUI)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_Activity_C", self, BattlePassModuleEvent.RemoveActivityTaskDatas, self.RemoveActivityList)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_Activity_C", self, BattlePassModuleEvent.UpdateBattlePassInfo, self.OnUpdateBattlePassInfo)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_Activity_C", self, BattlePassModuleEvent.UpdateActiveTableView, self.UpdateTable)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_Activity_C", self, BattlePassModuleEvent.OnCloseAwardMain, self.ClosePanel)
end

function UMG_Pass_Activity_C:OnConstruct()
  self:OnAddEventListener()
  self.curListData = {}
  self.lastIndex = 0
  self.LastTableIndex = 0
end

function UMG_Pass_Activity_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.SelectBattlePassWeekIndex, self.SelectWeekTable)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.UpdateActivityTaskDatas, self.RefreshUI)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.RemoveActivityTaskDatas, self.RemoveActivityList)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.UpdateBattlePassInfo, self.OnUpdateBattlePassInfo)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.UpdateActiveTableView, self.UpdateTable)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.OnCloseAwardMain, self.ClosePanel)
end

function UMG_Pass_Activity_C:OnActive(taskId)
  self.taskId = 0
  if taskId then
    self.taskId = taskId
  end
  self:RefreshUI()
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").TAB)
end

function UMG_Pass_Activity_C:UpdateTable(index)
  if self.LastTableIndex ~= index then
    self.lastIndex = -1
  end
  if 1 ~= index then
    self:ClosePanel()
  end
  self.LastTableIndex = index
end

function UMG_Pass_Activity_C:GetSelectIndex()
end

function UMG_Pass_Activity_C:ClosePanel()
  if self.curListData then
    local ids = {}
    for i = 1, #self.curListData do
      local taskId = self.curListData[i].id
      local uiItem = self.List:GetItemByIndex(i - 1)
      if UE4.UObject.IsValid(uiItem) and UE4.UObject.IsValid(uiItem.Dot) then
        _G.NRCModeManager:DoCmd(_G.RedPointModuleCmd.UnRegRedPointUI, uiItem.Dot)
        table.insert(ids, taskId)
      end
    end
    self.module:RemoveNewRedPoints(ids)
  end
  self:PlayOutWeekAnimation()
end

function UMG_Pass_Activity_C:RefreshUI()
  Log.Debug("UMG_Pass_Activity_C:RefreshUI")
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeColor, "UMG_Pass_Activity", self)
  self:UpdateWeekTabList()
  local tableIndex = -1
  if self.taskId and self.taskId > 0 then
    local taskConf = _G.DataConfigManager:GetTaskConf(self.taskId)
    if taskConf then
      local task_class = taskConf.task_class
      if task_class == _G.Enum.TaskClassType.TCT_BP_ROUTINE or task_class == _G.Enum.TaskClassType.TCT_BP_REPEAT then
        tableIndex = 0
      elseif task_class == _G.Enum.TaskClassType.TCT_BP then
        tableIndex = 1
      else
        tableIndex = -1
      end
    end
  end
  self.selectTabIndex = 0
  if -1 == tableIndex then
    self:SelectTabItem(self.selectTabIndex)
  else
    self:SelectTabItem(tableIndex)
  end
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.taskId = 0
end

function UMG_Pass_Activity_C:OnUpdateBattlePassInfo()
  local battlePassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  if self.recordThemeId and self.recordThemeId ~= battlePassInfo.theme_id then
    self:RefreshUI()
  end
  for i = 0, #self.curListData - 1 do
    local item = self.List:GetItemByIndex(i)
    item:SetThemeRes()
  end
end

function UMG_Pass_Activity_C:PlaySelectItemByIndex(index)
  local idx = index - 1
  for i = 0, 1 do
    local Item = self.Tab:GetItemByIndex(i)
    if i == idx then
      Item:PlaySelectAnimation()
    else
      Item:PlayOutAnimation()
    end
  end
  self.selectTabIndex = idx
end

function UMG_Pass_Activity_C:SelectTabItem(index)
  Log.Debug("UMG_Pass_Activity_C:SelectTabItem", index)
  if nil == index then
    return
  end
  local idx = index + 1
  local data = {}
  data.taskType = idx
  _G.NRCEventCenter:DispatchEvent(BattlePassModuleEvent.SelectBattlePassWeekIndex, idx, data)
end

function UMG_Pass_Activity_C:SelectWeekTable(index, data)
  Log.Debug("UMG_Pass_Activity_C:SelectWeekTable", index, data)
  if self.curListData and 2 == self.lastIndex then
    local ids = {}
    for i = 1, #self.curListData do
      local taskId = self.curListData[i].id
      local uiItem = self.List:GetItemByIndex(i - 1)
      if UE4.UObject.IsValid(uiItem) and UE4.UObject.IsValid(uiItem.Dot) then
        _G.NRCModeManager:DoCmd(_G.RedPointModuleCmd.UnRegRedPointUI, uiItem.Dot)
        table.insert(ids, taskId)
      end
    end
    self.module:RemoveNewRedPoints(ids)
  end
  self:StopListAnimation()
  local listData = {}
  listData = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetTasksByType, _G.Enum.TaskClassType.TCT_BP)
  local repeatTasks = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetTasksByType, _G.Enum.TaskClassType.TCT_BP_REPEAT)
  for i = 1, #repeatTasks do
    table.insert(listData, repeatTasks[i])
  end
  if listData and repeatTasks then
    Log.Info("UMG_Pass_Activity_C:SelectWeekTable list count:", #listData, #repeatTasks)
  end
  self.curListData = listData
  self:UpdateActivityList(listData, true)
  local AnimListData = self:GetAnimListData(listData, self.module.data:GetLastTaskListInfo())
  self:PlayListAnimation(AnimListData, true)
  self:PlaySelectItemByIndex(index)
  self.lastIndex = index
  self.List:SetScrollOffset(0)
end

function UMG_Pass_Activity_C:PlayInWeekAnimation()
  self:PlayAnimation(self.Huodong_In)
end

function UMG_Pass_Activity_C:PlayOutWeekAnimation()
  self:PlayAnimation(self.Huodong_Out)
end

function UMG_Pass_Activity_C:StopListAnimation()
  self:CancelDelay()
  local count = self.List:GetItemCount()
  for i = 0, count - 1 do
    local Item = self.List:GetItemByIndex(i)
    Item:StopAllAnimations()
  end
end

function UMG_Pass_Activity_C:PlayListAnimation(listData, isIn)
  local count = #listData
  if 0 == count then
    return
  end
  for i = 0, count - 1 do
    local Item = self.List:GetItemByIndex(i)
    Log.Info("UMG_Pass_AwardItem_C:PlayListAnimation SetRenderOpacity:", i, Item:GetName(), isIn)
    Item:SetRenderOpacity(isIn and 0 or 1)
    self:DelaySeconds(0.1 * (i + 1), function()
      if isIn then
        Item:SetRenderOpacity(1)
        Item:PlayInAnimation()
      end
      local itemData = listData[i + 1]
      if itemData then
        local taskState = itemData.taskInfo.state
        local lastTaskState = itemData.LastTaskState
        Log.Info("UMG_Pass_AwardItem_C:PlayListAnimation", Item:GetName(), taskState, lastTaskState)
        if taskState == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
          if lastTaskState ~= taskState then
            Item:PlayOutAnimation()
          else
            Item:PlayStampAnimation()
          end
        else
          Item:PlayNormalAnimation()
        end
      end
    end, self)
  end
end

function UMG_Pass_Activity_C:UpdateWeekTabList()
  local BattlePassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  self.recordThemeId = BattlePassInfo.theme_id
  local tableInfos = {}
  for i = 1, 2 do
    local tableInfo = {}
    tableInfo.taskType = i
    table.insert(tableInfos, tableInfo)
  end
  self.Tab:InitGridView(tableInfos)
end

function UMG_Pass_Activity_C:UpdateActivityList(taskInfoList, isHide)
  for i, v in pairs(taskInfoList) do
    v.isPlayNormal = true
  end
  taskInfoList = self.module.data:SortTaskList(taskInfoList)
  self.List:InitList(taskInfoList)
end

function UMG_Pass_Activity_C:RemoveActivityList(taskInfoList, rewards, LastTaskListInfo)
  local listData = {}
  if 0 == self.selectTabIndex then
    listData = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetTasksByType, _G.Enum.TaskClassType.TCT_BP)
    local repeatTasks = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetTasksByType, _G.Enum.TaskClassType.TCT_BP_REPEAT)
    for i = 1, #repeatTasks do
      table.insert(listData, repeatTasks[i])
    end
  end
  self.curListData = listData
  local AnimListData = self:GetAnimListData(listData, LastTaskListInfo)
  self:PlayListAnimation(AnimListData, false)
  self:UpdateActivityList(self.curListData, false)
  if rewards and #rewards > 0 then
    _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rewards, LuaText.battlepassmodule_4)
  end
end

function UMG_Pass_Activity_C:GetAnimListData(listData, LastTaskListInfo)
  local AnimListData = {}
  if nil == LastTaskListInfo then
    LastTaskListInfo = listData
  end
  for key, value in pairs(listData) do
    local lastTaskState = self.module.data:GetLastTaskState(value.id)
    table.insert(AnimListData, {taskInfo = value, LastTaskState = lastTaskState})
  end
  return AnimListData
end

return UMG_Pass_Activity_C
