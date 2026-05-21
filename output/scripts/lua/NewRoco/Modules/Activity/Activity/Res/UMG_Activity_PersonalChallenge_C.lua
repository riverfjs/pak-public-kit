local UMG_Activity_PersonalChallenge_C = _G.NRCPanelBase:Extend("UMG_Activity_PersonalChallenge_C")
local ActivityModuleEvent = require("NewRoco/Modules/System/Activity/ActivityModuleEvent")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")

function UMG_Activity_PersonalChallenge_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_Activity_PersonalChallenge_C:OnDestruct()
  self:RemoveAllButtonListener()
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.OnSelectChallengeTopItem, self.OnSelectChallengeTopItem)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.OnSelectChallengeLeftItem, self.OnSelectChallengeLeftItem)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.PeriodicLoginActivityGetReward, self.OnActivityRefresh)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.GlobalChallengeActivityDataRefresh, self.OnActivityRefresh)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.GetConditionRewardItemRewardSuccess, self.OnActivityRefresh)
end

function UMG_Activity_PersonalChallenge_C:OnAddEventListener()
  self:AddButtonListener(self.btnClose.btnClose, self.OnCloseBtnClick)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_PersonalChallenge_C", self, ActivityModuleEvent.OnSelectChallengeTopItem, self.OnSelectChallengeTopItem)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_PersonalChallenge_C", self, ActivityModuleEvent.OnSelectChallengeLeftItem, self.OnSelectChallengeLeftItem)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_PersonalChallenge_C", self, ActivityModuleEvent.PeriodicLoginActivityGetReward, self.OnActivityRefresh)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_PersonalChallenge_C", self, ActivityModuleEvent.GlobalChallengeActivityDataRefresh, self.OnActivityRefresh)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_PersonalChallenge_C", self, ActivityModuleEvent.GetConditionRewardItemRewardSuccess, self.OnActivityRefresh)
end

function UMG_Activity_PersonalChallenge_C:OnActive(param, param2, param3, param4, param5)
  self:PlayAnimation(self.In)
  if not param and not param2 then
    Log.Error("UMG_Activity_PersonalChallenge_C:OnActive param and param2 is nil")
    return
  end
  self:InitData(param, param2)
  self:RefreshTabList()
  self.TabList:SelectItemByIndex(0)
end

function UMG_Activity_PersonalChallenge_C:InitData(param, param2, param3, param4, param5)
  self.titleConf = _G.DataConfigManager:GetTitleConf("ChildrenChallengeProgressRewardPanel")
  local titleNameList = {}
  local selfChallengeActivityConf
  local serverChallengeActivityConf = {}
  local serverChallengeConfMap = {}
  local selfChallengeObject
  local serverChallengeObjectList = {}
  if param then
    table.insert(titleNameList, self:GetTitleSubtitle(1))
    selfChallengeActivityConf = _G.DataConfigManager:GetActivityConf(tonumber(param), true)
  end
  if param2 then
    table.insert(titleNameList, self:GetTitleSubtitle(2))
    for i, v in ipairs(param2) do
      table.insert(serverChallengeActivityConf, _G.DataConfigManager:GetActivityConf(tonumber(v), true))
    end
  end
  for i, v in ipairs(serverChallengeActivityConf) do
    serverChallengeConfMap[v.id] = v
  end
  if selfChallengeActivityConf then
    local ActivityObjectList_Condition = _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_ACTIVITY_CONDITION_REWARD, true)
    if ActivityObjectList_Condition and #ActivityObjectList_Condition > 0 then
      for i, activityObject in ipairs(ActivityObjectList_Condition) do
        local activityId = activityObject:GetActivityId()
        if activityId == selfChallengeActivityConf.id then
          selfChallengeObject = activityObject
          break
        end
      end
    end
  end
  if #serverChallengeActivityConf > 0 then
    local ActiveObjectList_Global = _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_GLOBAL_CHALLENGE, true)
    if ActiveObjectList_Global and #ActiveObjectList_Global > 0 then
      for i, activityObject in ipairs(ActiveObjectList_Global) do
        local activityId = activityObject:GetActivityId()
        if serverChallengeConfMap[activityId] then
          serverChallengeObjectList[activityId] = activityObject
        end
      end
    end
  end
  self.titleNameList = titleNameList
  self.curTopTabIndex = #titleNameList > 0 and 1 or 0
  self.curLeftTabId = #serverChallengeActivityConf > 0 and serverChallengeActivityConf[1].id or 0
  self.selfChallengeConf = selfChallengeActivityConf
  self.serverChallengeConfList = serverChallengeActivityConf
  self.serverChallengeConfMap = serverChallengeConfMap
  self.selfChallengeObject = selfChallengeObject
  self.serverChallengeObjectList = serverChallengeObjectList
end

function UMG_Activity_PersonalChallenge_C:RefreshTabList(onlyRefreshRedPoint)
  if not onlyRefreshRedPoint then
    self.Title1:SetTitle("ChildrenChallengeProgressRewardPanel")
    self.TabList:InitGridView(self.titleNameList)
    self.Appearance_Tab1:SetCustomData({
      curSelectId = self.curLeftTabId
    })
    self.Appearance_Tab1:InitGridView(self.serverChallengeConfList)
  end
  for i = 1, #self.titleNameList do
    local topTabItem = self.TabList:GetItemByIndex(i - 1)
    if topTabItem then
      topTabItem:SetRedPoint(self:HaveCanGetReward(i))
    end
  end
  for i = 1, #self.serverChallengeConfList do
    local leftTabItem = self.Appearance_Tab1:GetItemByIndex(i - 1)
    if leftTabItem then
      leftTabItem:SetRedPoint(self:HaveCanGetReward(2, i))
    end
  end
end

function UMG_Activity_PersonalChallenge_C:OnActivityRefresh(rewardData)
  if rewardData and rewardData.rewards and #rewardData.rewards > 0 then
    _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, table.deepCopy(rewardData.rewards))
  end
  self:RefreshTabList(true)
  self:RefreshRightList()
end

function UMG_Activity_PersonalChallenge_C:OnSelectChallengeTopItem(topIndex)
  local bTopChange = self.curTopTabIndex > 0 and self.curTopTabIndex ~= topIndex
  self.curTopTabIndex = topIndex
  self.Title1:SetSubtitle(self:GetTitleSubtitle(topIndex))
  if 1 == topIndex then
    self.Appearance_Tab1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.selfChallengeObject then
      self.GashaponMachine:SetPath(self.selfChallengeObject:GetShowIllustration())
    end
  elseif 2 == topIndex then
    self.Appearance_Tab1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self:RefreshLeftProgress()
    if bTopChange then
      self.Appearance_Tab1:SelectItemByIndex(0)
    end
  end
  self:RefreshRightList()
end

function UMG_Activity_PersonalChallenge_C:OnSelectChallengeLeftItem(leftTabId)
  self.curLeftTabId = leftTabId
  self:RefreshLeftProgress()
  self:RefreshRightList()
  if self.serverChallengeObjectList[leftTabId] then
    local conf = self.serverChallengeObjectList[leftTabId]:GetShowPartConf()
    if conf then
      self.GashaponMachine:SetPath(conf.img)
    end
  end
end

function UMG_Activity_PersonalChallenge_C:RefreshLeftProgress()
  local activityObject = self.serverChallengeObjectList[self.curLeftTabId]
  if activityObject then
    local showPartConf = activityObject:GetShowPartConf()
    if showPartConf then
      local curProgress = activityObject:GetCurProgress()
      local maxProgress = showPartConf.require_count
      self.NRCText_0:SetText(showPartConf.img_des)
      self.ProgressText:SetText(curProgress > 9999999999999 and "9999999999999..." or curProgress)
      self.TaskProgress:SetFillAmount(math.max(curProgress / maxProgress, 0))
    end
  end
end

function UMG_Activity_PersonalChallenge_C:RefreshRightList()
  self:PlayAnimation(self.Change)
  local showItemList, activityObject = self:GetRightListShowInfo()
  local curCount = self.PersonalProgressList:GetItemCount()
  if curCount > #showItemList then
    for i = 0, curCount - 1 do
      local item = self.PersonalProgressList:GetItemByIndex(i)
      if item then
        item:SetVisibility(UE4.ESlateVisibility.Collapsed, true)
      end
    end
  end
  if self.ScrollBox_49 then
    self.ScrollBox_49:ScrollToStart()
  end
  self.PersonalProgressList:SetCustomData({
    challengeType = self.curTopTabIndex,
    activityInst = activityObject
  })
  self.PersonalProgressList:InitGridView(showItemList)
end

function UMG_Activity_PersonalChallenge_C:GetRightListShowInfo()
  local activityObject
  local returnItems = {}
  if 1 == self.curTopTabIndex then
    activityObject = self.selfChallengeObject
    if activityObject then
      local itemList = activityObject:GetRewardItems()
      for i, v in ipairs(itemList) do
        v:UpdateProgress()
        local item = {}
        item.partId = v.conf.id
        item.rewardState = v:GetRewardStatus()
        table.insert(returnItems, item)
      end
    end
  elseif 2 == self.curTopTabIndex then
    activityObject = self.serverChallengeObjectList[self.curLeftTabId]
    if activityObject then
      local partIds = activityObject:GetPartIds()
      if partIds then
        for i, v in ipairs(partIds) do
          local item = {}
          item.partId = v
          item.rewardState = activityObject:GetSinglePartStatus(v)
          table.insert(returnItems, item)
        end
      end
    end
  end
  self:StableSort(returnItems)
  return returnItems, activityObject
end

function UMG_Activity_PersonalChallenge_C:StableSort(itemList)
  if not itemList or #itemList <= 1 then
    return
  end
  for i = 1, #itemList do
    for j = 1, #itemList - i do
      local aData = itemList[j]
      local bData = itemList[j + 1]
      local aWeight = aData.rewardState == ActivityEnum.RewardStatus.Available and -1 or aData.rewardState
      local bWeight = bData.rewardState == ActivityEnum.RewardStatus.Available and -1 or bData.rewardState
      if aWeight > bWeight then
        itemList[j], itemList[j + 1] = itemList[j + 1], itemList[j]
      end
    end
  end
end

function UMG_Activity_PersonalChallenge_C:GetTitleSubtitle(index)
  if self.titleConf and self.titleConf.subtitle then
    for i, v in ipairs(self.titleConf.subtitle) do
      if i == index then
        return v.subtitle
      end
    end
  end
  return ""
end

function UMG_Activity_PersonalChallenge_C:HaveCanGetReward(topTabIndex, leftTabId)
  if 1 == topTabIndex then
    if self.selfChallengeObject then
      local itemList = self.selfChallengeObject:GetRewardItems()
      if itemList then
        for i, v in ipairs(itemList) do
          if v:GetRewardStatus() == ActivityEnum.RewardStatus.Available then
            return true
          end
        end
      end
    end
  elseif 2 == topTabIndex then
    if leftTabId then
      local _index = 0
      for i, activityObject in pairs(self.serverChallengeObjectList) do
        _index = _index + 1
        if _index == leftTabId then
          if activityObject:HaveCanGetReward() then
            return true
          end
          break
        end
      end
    else
      for i, activityObject in pairs(self.serverChallengeObjectList) do
        if activityObject:HaveCanGetReward() then
          return true
        end
      end
    end
  end
  return false
end

function UMG_Activity_PersonalChallenge_C:OnCloseBtnClick()
  self:PlayAnimation(self.Out)
end

function UMG_Activity_PersonalChallenge_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self:DoClose()
  end
end

return UMG_Activity_PersonalChallenge_C
