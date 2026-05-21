local UMG_TeachingSubPanel_C = _G.NRCPanelBase:Extend("UMG_TeachingSubPanel_C")

function UMG_TeachingSubPanel_C:OnEnable(module)
  self.module = module
  self.data = self.module.data
  local challengeTabList = {
    {
      Icon = "",
      Sort = self.data.TeachType.Restraint,
      open = true,
      TaskTypeName = LuaText.type_advantage_teach_headline
    },
    {
      Icon = "",
      Sort = self.data.TeachType.Battle,
      open = true,
      TaskTypeName = LuaText.combat_mechanism_teach_headline
    }
  }
  self.challengeTabList = challengeTabList
  self.TabList2:InitGridView(challengeTabList)
  if self.module.SubTableIndex > -1 and self.module.SubTableIndex < #challengeTabList then
    self:SelectTabBySubTabIndex(self.module.SubTableIndex)
    self.module.SubTableIndex = -1
  elseif (self.module.ChildTableIndex or 0) > 0 then
    self:SelectTabBySubTabIndex(self.module.ChildTableIndex)
    self.module.ChildTableIndex = 0
  else
    self.TabList2:SelectItemByIndex(0)
  end
  self:PlayAnimation(self.Change)
  self:OnAddEventListener()
end

function UMG_TeachingSubPanel_C:SelectTabBySubTabIndex(TabIndex)
  if self.challengeTabList and #self.challengeTabList > 0 then
    local index = 0
    for i, v in ipairs(self.challengeTabList) do
      if v.Sort == TabIndex then
        index = i - 1
      end
    end
    self.TabList2:SelectItemByIndex(index)
  end
end

function UMG_TeachingSubPanel_C:checkTabIndexByBattleId(tabList, Sort)
  if not tabList or 0 == #tabList then
    return
  end
  if not self.module.OpenTeachBattleId then
    return
  end
  if Sort == self.data.TeachType.Restraint then
    for i, v in ipairs(tabList) do
      local tasks = v.data and v.data.tasks
      if tasks and #tasks > 0 then
        for _, k in ipairs(tasks) do
          if k.conf and k.conf.data[1] == self.module.OpenTeachBattleId then
            return i - 1
          end
        end
      end
    end
  elseif Sort == self.data.TeachType.Battle then
    for i, v in ipairs(tabList) do
      local tasks = v.data and v.data.tasks
      if tasks and #tasks > 0 then
        for _, k in ipairs(tasks) do
          if k.conf and k.conf.data == self.module.OpenTeachBattleId then
            return i - 1
          end
        end
      end
    end
  end
  self.module.OpenTeachBattleId = nil
end

function UMG_TeachingSubPanel_C:GetTabList(Sort)
  local tabList = {}
  if Sort == self.data.TeachType.Restraint then
    local redNewPointList = {}
    local redRewardPointList = {}
    local RedPointList = _G.DataModelMgr.PlayerDataModel:GetRedPointInfo()
    for k, v in ipairs(RedPointList) do
      if v.reason_type == _G.Enum.RedPointReason.RPR_LOCK_TYPE_DAVANTAGE and v.point_data and #v.point_data > 0 then
        for key, val in ipairs(v.point_data) do
          local Id = tonumber(val)
          table.insert(redNewPointList, Id)
        end
      end
      if v.reason_type == _G.Enum.RedPointReason.RPR_TYPE_BATTLE_TRAIN_REWARD and v.point_data and #v.point_data > 0 then
        for key, val in ipairs(v.point_data) do
          local delimiter = "."
          local subValues = {}
          for subValue in string.gmatch(val, "([^" .. delimiter .. "]+)") do
            table.insert(subValues, subValue)
          end
          local id = subValues[2] and tonumber(subValues[2])
          local type = subValues[1] and tonumber(subValues[1])
          if type == Enum.TeachingType.TT_TYPE_ADVANTAGE then
            table.insert(redRewardPointList, id)
          end
        end
      end
    end
    
    local function sortTabList(a, b)
      local A_id = a and a.data and a.data.id
      local B_id = b and b.data and b.data.id
      local A_order = a and a.data and a.data.conf and a.data.conf.list_order or 999
      local B_order = b and b.data and b.data.conf and b.data.conf.list_order or 999
      if table.contains(redNewPointList, A_id) and not table.contains(redNewPointList, B_id) then
        return true
      elseif not table.contains(redNewPointList, A_id) and table.contains(redNewPointList, B_id) then
        return false
      elseif table.contains(redRewardPointList, A_id) and not table.contains(redRewardPointList, B_id) then
        return true
      elseif not table.contains(redRewardPointList, A_id) and table.contains(redRewardPointList, B_id) then
        return false
      elseif a.data.is_unlock and not b.data.is_unlock then
        return true
      elseif not a.data.is_unlock and b.data.is_unlock then
        return false
      elseif A_order ~= B_order then
        return A_order < B_order
      else
        return A_id < B_id
      end
    end
    
    for i, v in ipairs(self.module.data.TeachingTabInfo.type_advantage) do
      table.insert(tabList, {
        type = self.data.TeachType.Restraint,
        data = v
      })
    end
    table.sort(tabList, sortTabList)
  elseif Sort == self.data.TeachType.Battle then
    local redRewardPointList = {}
    local RedPointList = _G.DataModelMgr.PlayerDataModel:GetRedPointInfo()
    for k, v in ipairs(RedPointList) do
      if v.reason_type == _G.Enum.RedPointReason.RPR_TYPE_BATTLE_TRAIN_REWARD and v.point_data and #v.point_data > 0 then
        for key, val in ipairs(v.point_data) do
          local delimiter = "."
          local subValues = {}
          for subValue in string.gmatch(val, "([^" .. delimiter .. "]+)") do
            table.insert(subValues, subValue)
          end
          local id = subValues[2] and tonumber(subValues[2])
          local type = subValues[1] and tonumber(subValues[1])
          if type == Enum.TeachingType.TT_COMBAT_MECHANISM then
            table.insert(redRewardPointList, id)
          end
        end
      end
    end
    
    local function sortTabList(a, b)
      local A_id = a and a.data and a.data.id
      local B_id = b and b.data and b.data.id
      if a.data.is_unlock and not b.data.is_unlock then
        return true
      elseif not a.data.is_unlock and b.data.is_unlock then
        return false
      else
        return A_id < B_id
      end
    end
    
    for i, v in ipairs(self.module.data.TeachingTabInfo.combat_mechanism) do
      table.insert(tabList, {
        type = self.data.TeachType.Battle,
        data = v
      })
    end
    table.sort(tabList, sortTabList)
  end
  local selectIndex = self:checkTabIndexByBattleId(tabList, Sort)
  return tabList, selectIndex
end

function UMG_TeachingSubPanel_C:OnRefreshTeachUI(type, _data, _conf)
  self.PreTask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local tasks = {}
  if _data and _data.tasks then
    for i, v in ipairs(_data.tasks) do
      table.insert(tasks, {
        data = v,
        type = type,
        ConfId = _conf.id
      })
    end
  end
  table.sort(tasks, function(a, b)
    if a.data.is_reward and not b.data.is_reward then
      return false
    elseif not a.data.is_reward and b.data.is_reward then
      return true
    end
    return a.data.id < b.data.id
  end)
  if type == self.data.TeachType.Restraint then
    if _conf and _data and _data.is_unlock then
      self.curConf = _conf
      self:SwitcherToTaskType(1)
      self.Image_35:SetPath(_conf.type_advantage_resource)
      self.ImageText:SetText(_conf.type_advantage_depict)
      self.Describe1:SetText(_conf.type_display)
      self.TitleIcon:SetPath(_conf.type_icon_resource)
      self.TitleText:SetText(_conf.type_battle_display_name)
      self.List:InitGridView(tasks)
    elseif _conf and _data then
      self.Describe:SetText(string.format(_conf.unlock_display, _data.unlock_progress[1].count, _conf.type_advantage_unlock_type_param2[1]))
      self.Task1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Task2:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.PreTask:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  elseif type == self.data.TeachType.Battle then
    if _conf and _data and _data.is_unlock then
      self:SwitcherToTaskType(2)
      self.List_1:InitList(tasks)
      self.List:InitGridView(tasks)
    elseif _conf and _data then
      if 2 == _data.id then
        self.Describe:SetText(_G.DataConfigManager:GetGlobalConfigStrByKey("combat_battle_teach2_unlock"))
      elseif 3 == _data.id then
        self.Describe:SetText(_G.DataConfigManager:GetGlobalConfigStrByKey("combat_battle_teach3_unlock"))
      end
      self.Task1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Task2:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.PreTask:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
end

function UMG_TeachingSubPanel_C:OnRefreshTeachTabUI(tabIndex, Sort, tableName)
  self.sort = Sort
  local TabList, selectIndex = self:GetTabList(Sort)
  self.TabList:InitList(TabList)
  self.TabList:SelectItemByIndex(selectIndex or 0)
end

function UMG_TeachingSubPanel_C:OnRefreshPanel()
  local count = self.TabList:GetItemCount()
  for i = 0, count - 1 do
    local item = self.TabList:GetItemByIndex(i)
    if item then
      item:OnRefreshData()
    end
  end
  if self.sort == self.data.TeachType.Restraint then
    local TaskCount = self.List:GetItemCount()
    for i = 0, TaskCount - 1 do
      local item = self.List:GetItemByIndex(i)
      if item then
        item:OnRefresh()
      end
    end
  elseif self.sort == self.data.TeachType.Battle then
    local TaskCount = self.List_1:GetItemCount()
    for i = 0, TaskCount - 1 do
      local item = self.List_1:GetItemByIndex(i)
      if item then
        item:OnRefresh()
      end
    end
  end
end

function UMG_TeachingSubPanel_C:SwitcherToTaskType(index)
  self.Task1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Task2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self["Task" .. index]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_TeachingSubPanel_C:OnDisable()
  self:OnRemoveEventListener()
end

function UMG_TeachingSubPanel_C:OnAddEventListener()
  self:AddButtonListener(self.MagicManualKnowBtn.btnLevelUp, self.OnKnowBtnClicked)
  self:AddButtonListener(self.ImageBtn, self.OnClickTips)
  self:AddButtonListener(self.ImageBtn1, self.OnClickTips)
  self:AddButtonListener(self.ViewBtn.btnLevelUp, self.OnClickTips)
end

function UMG_TeachingSubPanel_C:OnKnowBtnClicked()
  if self.module:HasPanel("MagicManualMainPanel") then
    local Panel = self.module:GetPanel("MagicManualMainPanel")
    if Panel:IsInOutAnim() then
      return
    end
  end
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local title = LuaText.TIPS
  local Content = ""
  if self.sort == self.data.TeachType.Restraint then
    Content = LuaText.type_advantage_teach
  elseif self.sort == self.data.TeachType.Battle then
    Content = LuaText.combat_mechanism_teach
  end
  Context:SetTitle(title):SetContent(Content):SetMode(DialogContext.Mode.NotBtn):SetCloseOnCancel(true):SetCloseOnOK(true)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_TeachingSubPanel_C:OnClickTips()
  _G.NRCModuleManager:DoCmd(MagicManualModuleCmd.OpenMagicManualTeachingTips, self.curConf)
end

function UMG_TeachingSubPanel_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.MagicManualKnowBtn.btnLevelUp)
  self:RemoveButtonListener(self.ViewBtn.btnLevelUp)
  self:RemoveButtonListener(self.ImageBtn)
  self:RemoveButtonListener(self.ImageBtn1)
end

return UMG_TeachingSubPanel_C
