local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local UMG_Activity_BackflowContractManual_C = Base:Extend("UMG_Activity_BackflowContractManual_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")

function UMG_Activity_BackflowContractManual_C:BindUIElements()
  local uiElements = {}
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  return uiElements
end

function UMG_Activity_BackflowContractManual_C:OnConstruct()
  Base.OnConstruct(self)
  local mainActivityObjects = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_ACTIVITY_RECALL, true)
  if mainActivityObjects and #mainActivityObjects > 0 then
    local mainActivityObject
    for _, object in ipairs(mainActivityObjects) do
      local recall_data = object:GetActivityData()
      if recall_data and recall_data.active then
        mainActivityObject = object
        break
      end
    end
    if mainActivityObject then
      local mainActivityData = mainActivityObject:GetActivityData()
      if mainActivityData then
        local textStr = _G.DataConfigManager:GetActivityRecallClassConf(mainActivityData.recall_class).bp_welcome_txt
        self.Text_Dialogue:SetText(textStr)
      end
    end
  end
  local recallBPConf = _G.DataConfigManager:GetActivityRecallbpConf(self.activityInst:GetSinglePartId())
  local BP_data = table.new(#recallBPConf.level_reward_group)
  local activity_id = self.activityInst:GetActivityId()
  for _, v in ipairs(recallBPConf.level_reward_group) do
    local level = v.bp_level
    BP_data[level] = {}
    BP_data[level].bp_level = level
    BP_data[level].bp_level_exp = v.next_need_exp
    BP_data[level].reward_id = v.level_reward1
    BP_data[level].is_paid = 1 == v.is_paid1
    BP_data[level].reward_id2 = v.level_reward2
    BP_data[level].is_paid2 = 1 == v.is_paid2
    BP_data[level].activity_id = activity_id
  end
  self.BP_data = BP_data
  self.task_data1 = {}
  self.task_data2 = {}
  for _, v in ipairs(recallBPConf.condition_group) do
    local data = {}
    data.task_id = v.bp_task
    data.taskText = _G.DataConfigManager:GetTaskConf(v.bp_task).task_des
    data.exp_num = v.task_exp
    data.option_id = v.task_action
    data.caller = self
    data.callBack = self.GetExp
    data.activity_id = activity_id
    if 1 == v.is_daily then
      table.insert(self.task_data2, data)
    else
      table.insert(self.task_data1, data)
    end
  end
  self:AddButtonListener(self.BtnUpgrade.btnLevelUp, self.OpenShopTips)
  self:RegisterEvent(self, ActivityModuleEvent.OnBPUnlock, self.OnBPUnlock)
  self:RegisterEvent(self, ActivityModuleEvent.RefreshBPActivityData, self.InitPanel)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_BackflowContractManual_C", self, ActivityModuleEvent.TryGetBPReward, self.TryGetBPReward)
  self:InitPanel(self.activityInst:GetActivityData())
  self.BtnUpgradeGray:SetShowLockIcon(false)
end

function UMG_Activity_BackflowContractManual_C:InitPanel(activity_data)
  local bMaxLevel
  if activity_data then
    local level = 0
    local total_exp = activity_data.bp_exp or 0
    local remainExp = 0
    local targetExp = self.BP_data[1].bp_level_exp
    for _, v in ipairs(activity_data.reward_list) do
      self.BP_data[v.bp_level].state = v.reward1_state
      self.BP_data[v.bp_level].state2 = v.reward2_state
    end
    for _, v in ipairs(self.BP_data) do
      remainExp = total_exp
      total_exp = total_exp - v.bp_level_exp
      if total_exp >= 0 then
        level = level + 1
      else
        targetExp = v.bp_level_exp
        break
      end
    end
    self.level = level
    if level == #self.BP_data then
      remainExp = self.BP_data[#self.BP_data].bp_level_exp
      targetExp = remainExp
    end
    self.remainExp = remainExp
    self.Text_Cass:SetText(level)
    self.Schedule_Number:SetText(remainExp)
    self.UpperLimit_Number:SetText("/" .. tostring(targetExp))
    self.Schedule:SetPercent(remainExp / targetExp)
    if activity_data.is_paid then
      self.BtnUpgrade:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.BtnUpgradeGray:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.BtnUpgrade:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.BtnUpgradeGray:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.bPaid = activity_data.is_paid
    bMaxLevel = level == #self.BP_data
    for _, v in ipairs(activity_data.task_list) do
      for _, v1 in ipairs(self.task_data1) do
        if v.task_id == v1.task_id then
          v1.state = v.state
          v1.bMaxLevel = bMaxLevel
          goto lbl_151
        end
      end
      for _, v2 in ipairs(self.task_data2) do
        if v.task_id == v2.task_id then
          v2.state = v.state
          v2.bMaxLevel = bMaxLevel
          break
        end
      end
      ::lbl_151::
    end
  else
    for _, v in ipairs(self.BP_data) do
      v.state = _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNFINISH
      if 0 ~= v.reward_id2 then
        v.state2 = _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNFINISH
      end
    end
    self.Text_Cass:SetText(0)
    self.Schedule_Number:SetText(0)
    self.UpperLimit_Number:SetText("/" .. tostring(self.BP_data[1].bp_level_exp))
    self.Schedule:SetPercent(0)
    self.BtnUpgrade:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BtnUpgradeGray:SetVisibility(UE4.ESlateVisibility.Collapsed)
    for _, v in ipairs(self.task_data1) do
      v.state = _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNFINISH
    end
    for _, v in ipairs(self.task_data2) do
      v.state = _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNFINISH
    end
  end
  local activity_id = self.activityInst:GetActivityId()
  local tabData = {
    {
      text = _G.LuaText.recall_bp_finaltask,
      caller = self,
      callBack = self.refreshTaskList,
      activity_id = activity_id
    },
    {
      text = _G.LuaText.recall_bp_dailytask,
      caller = self,
      callBack = self.refreshTaskList,
      activity_id = activity_id
    }
  }
  self.TabList1:InitGridView(tabData)
  local tabIndex = 1
  for _, v in ipairs(self.task_data1) do
    if v.state ~= _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
      tabIndex = 0
      break
    end
  end
  self.TabList1:SelectItemByIndex(tabIndex)
  self.AwardList:InitList(self.BP_data)
  if bMaxLevel then
    self:EraseTabRedPoints()
  end
  self.delayId = _G.DelayManager:DelayFrames(2, function()
    local halfSize, fullSize
    self.lengthArray = {}
    local length = 0
    local initLength = 1
    local waitLength, unFinishLength
    for i, v in ipairs(self.BP_data) do
      if not waitLength and (v.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT or v.state2 == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT) then
        waitLength = length
      end
      if not unFinishLength and (v.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNFINISH or v.state2 == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNFINISH) then
        unFinishLength = length
      end
      if 0 == v.reward_id2 then
        if not halfSize then
          local item = self.AwardList:GetItemByIndex(i - 1)
          halfSize = item:GetDesiredSize().X
        end
        length = length + halfSize
      else
        if not fullSize then
          local item = self.AwardList:GetItemByIndex(i - 1)
          fullSize = item:GetDesiredSize().X
        end
        if v.is_paid2 then
          table.insert(self.lengthArray, {
            i,
            length + 0.25 * fullSize
          })
        end
        length = length + fullSize
      end
    end
    if waitLength and waitLength > 0 then
      initLength = waitLength
    elseif unFinishLength and unFinishLength > 0 then
      initLength = unFinishLength
    end
    self.AwardList:BindLuaCallback({
      self,
      self.OnScrollCallback
    })
    local listSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.AwardList:GetCachedGeometry())
    self.AwardList:NRCSetScrollOffset(length > initLength + listSize.X and initLength or length - listSize.X, true)
  end)
end

function UMG_Activity_BackflowContractManual_C:EraseTabRedPoints()
  for i = 0, self.TabList1:GetItemCount() - 1 do
    local item = self.TabList1:GetItemByIndex(i)
    item:EraseRedPoint()
  end
end

function UMG_Activity_BackflowContractManual_C:OnScrollCallback(offset)
  local listSize = UE4.USlateBlueprintLibrary.GetLocalSize(self.AwardList:GetCachedGeometry())
  local length = offset + listSize.X
  if self.item_index then
    local max = self.lengthArray[self.length_index][2]
    local min = 1 == self.length_index and 0 or self.lengthArray[self.length_index - 1][2]
    if length < max and length >= min then
      return
    end
  end
  local item_index = self.lengthArray[#self.lengthArray][1]
  local length_index = #self.lengthArray
  for i, v in ipairs(self.lengthArray) do
    if length < v[2] then
      item_index = v[1]
      length_index = i
      break
    end
  end
  if self.item_index ~= item_index then
    self.item_index = item_index
    self.length_index = length_index
    self.AwardItem:OnItemUpdate(self.BP_data[item_index], nil, -1)
  end
end

function UMG_Activity_BackflowContractManual_C:refreshTaskList(tabIndex)
  local bForceNoCreate = tabIndex == self.selectTabIndex
  self.selectTabIndex = tabIndex
  if 1 == tabIndex then
    self.List:InitList(self.task_data1, bForceNoCreate)
  elseif 2 == tabIndex then
    self.List:InitList(self.task_data2, bForceNoCreate)
  end
end

function UMG_Activity_BackflowContractManual_C:GetExp(exp_num)
  local popupInitData = {}
  local popupData = _G.ProtoMessage:newGoodsItem()
  popupData.id = _G.Enum.VisualItem.VI_RECALLBP_EXP
  popupData.num = exp_num
  popupData.type = _G.Enum.GoodsType.GT_VITEM
  table.insert(popupInitData, popupData)
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNPCShopItemRewardsPanel, popupInitData)
  local maxLevel = #self.BP_data
  if self.level == maxLevel then
    return
  end
  if not self.bStartTick then
    self.nowLevel = self.level
    self.nowPercent = self.remainExp / self.BP_data[self.level + 1].bp_level_exp
    self.bStartTick = true
    _G.UpdateManager:Register(self)
  end
  local level = self.level
  local remainExp = self.remainExp + exp_num
  local targetExp = self.BP_data[level + 1].bp_level_exp
  for i = level + 1, maxLevel do
    local exp = remainExp - self.BP_data[i].bp_level_exp
    if exp < 0 then
      targetExp = self.BP_data[level + 1].bp_level_exp
      break
    else
      level = level + 1
      remainExp = exp
      if not self.BP_data[i].is_paid or not not self.bPaid then
        self.BP_data[i].state = _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT
      end
      if (not self.BP_data[i].is_paid2 or not not self.bPaid) and 0 ~= self.BP_data[i].reward_id2 then
        self.BP_data[i].state2 = _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT
      end
    end
    if i == maxLevel then
      targetExp = self.BP_data[maxLevel].bp_level_exp
      remainExp = targetExp
      for _, v in ipairs(self.task_data1) do
        v.bMaxLevel = true
      end
      for _, v in ipairs(self.task_data2) do
        v.bMaxLevel = true
      end
      self:refreshTaskList(self.selectTabIndex)
      self:EraseTabRedPoints()
    end
  end
  if level ~= self.level then
    self.level = level
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.safeFormat(_G.LuaText.recallbp_levelup, level), nil, nil, 1.2)
  end
  self.remainExp = remainExp
  self.targetLevel = level
  self.targetPercent = remainExp / targetExp
  self.AwardList:InitList(self.BP_data, true)
  self.AwardItem:OnItemUpdate(self.BP_data[self.item_index])
end

function UMG_Activity_BackflowContractManual_C:OnTick(deltaTime)
  if not self.bStartTick then
    _G.UpdateManager:UnRegister(self)
    return
  end
  local maxLevel = #self.BP_data
  self.nowPercent = self.nowPercent + deltaTime * 1
  if self.nowLevel == self.targetLevel then
    if self.nowPercent >= self.targetPercent then
      self.nowPercent = self.targetPercent
      self.bStartTick = false
      _G.UpdateManager:UnRegister(self)
    end
  elseif self.nowPercent > 1 then
    self.nowLevel = self.nowLevel + 1
    self.nowPercent = self.nowPercent - 1
    if maxLevel > self.nowLevel then
      if self.nowLevel == self.targetLevel and self.nowPercent >= self.targetPercent then
        self.nowPercent = self.targetPercent
        self.bStartTick = false
        _G.UpdateManager:UnRegister(self)
      end
    else
      self.nowPercent = 1
      self.bStartTick = false
      _G.UpdateManager:UnRegister(self)
    end
    self.Text_Cass:SetText(self.nowLevel)
    self.UpperLimit_Number:SetText("/" .. tostring(self.BP_data[self.nowLevel == maxLevel and maxLevel or self.nowLevel + 1].bp_level_exp))
  end
  self.Schedule:SetPercent(self.nowPercent)
  self.Schedule_Number:SetText(math.round(self.nowPercent * self.BP_data[self.nowLevel == maxLevel and maxLevel or self.nowLevel + 1].bp_level_exp))
end

function UMG_Activity_BackflowContractManual_C:OpenShopTips()
  _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenContractManualShopTips, self.activityInst:GetActivityId())
end

function UMG_Activity_BackflowContractManual_C:TryGetBPReward()
  local req = _G.ProtoMessage:newZoneReceiveActivityRecallBpLevelRewardReq()
  req.activity_id = self.activityInst:GetActivityId()
  req.bp_level = self.level
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_ACTIVITY_RECALL_BP_LEVEL_REWARD_REQ, req, self, self.GetBPReward)
end

function UMG_Activity_BackflowContractManual_C:GetBPReward(rsp)
  if 0 == rsp.ret_info.ret_code then
    local popupInitData = {}
    for _, v in ipairs(self.BP_data) do
      if v.state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
        v.state = _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE
        local rewardData = _G.DataConfigManager:GetRewardConf(v.reward_id).RewardItem[1]
        local bFind = false
        for _, initData in ipairs(popupInitData) do
          if initData.id == rewardData.Id and initData.type == rewardData.Type then
            initData.num = initData.num + rewardData.Count
            bFind = true
            break
          end
        end
        if not bFind then
          local popupData = _G.ProtoMessage:newGoodsItem()
          popupData.id = rewardData.Id
          popupData.num = rewardData.Count
          popupData.type = rewardData.Type
          table.insert(popupInitData, popupData)
        end
      end
      if v.state2 == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
        v.state2 = _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE
        local rewardData = _G.DataConfigManager:GetRewardConf(v.reward_id2).RewardItem[1]
        local bFind = false
        for _, initData in ipairs(popupInitData) do
          if initData.id == rewardData.Id and initData.type == rewardData.Type then
            initData.num = initData.num + rewardData.Count
            bFind = true
            break
          end
        end
        if not bFind then
          local popupData = _G.ProtoMessage:newGoodsItem()
          popupData.id = rewardData.Id
          popupData.num = rewardData.Count
          popupData.type = rewardData.Type
          table.insert(popupInitData, popupData)
        end
      end
    end
    _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNPCShopItemRewardsPanel, popupInitData)
    self.AwardList:InitList(self.BP_data, true)
    self.AwardItem:OnItemUpdate(self.BP_data[self.item_index])
  end
end

function UMG_Activity_BackflowContractManual_C:OnBPUnlock()
  self.bPaid = true
  for i = 1, self.level do
    if self.BP_data[i].is_paid then
      self.BP_data[i].state = _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT
    end
    if self.BP_data[i].is_paid2 then
      self.BP_data[i].state2 = _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT
    end
  end
  self.AwardList:InitList(self.BP_data, true)
  self.AwardItem:OnItemUpdate(self.BP_data[self.item_index])
  self.BtnUpgrade:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.BtnUpgradeGray:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Activity_BackflowContractManual_C:OnDestruct()
  self:RemoveButtonListener(self.BtnUpgrade.btnLevelUp)
  self:UnRegisterEvent(self, ActivityModuleEvent.OnBPUnlock)
  self:UnRegisterEvent(self, ActivityModuleEvent.RefreshBPActivityData)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.TryGetBPReward, self.TryGetBPReward)
  _G.DelayManager:CancelDelayById(self.delayId)
  self.activityInst:ClearActivityData()
  Base.OnDestruct(self)
end

return UMG_Activity_BackflowContractManual_C
