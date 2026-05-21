local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local UMG_Activity_StageAward_C = Base:Extend("UMG_Activity_StageAward_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local RewardItemOpType = {
  Enable = 1,
  RefreshData = 2,
  RewardReceived = 3,
  ProgressChange = 4
}

function UMG_Activity_StageAward_C:BindUIElements()
  local uiElements = {}
  uiElements.desireActivityType = Enum.ActivityType.ATP_ACTIVITY_CONDITION_REWARD
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.bgImage = self.Image_Bg
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  uiElements.closeAnimName = "Out"
  return uiElements
end

function UMG_Activity_StageAward_C:OnConstruct()
  Base.OnConstruct(self)
  self:RegisterEvent(self, ActivityModuleEvent.ConditionRewardItemStatusChange, self.OnConditionRewardItemStatusChange)
  self:RegisterEvent(self, ActivityModuleEvent.ConditionRewardItemProgressChange, self.OnConditionRewardItemProgressChange)
  if self.ExchangeStoreBtn then
    self:AddButtonListener(self.ExchangeStoreBtn, self.GotoShop)
  end
  local activityInst = self.activityInst
  if self.NRCText_61 then
    self.NRCText_61:SetText(activityInst:GetTitleIconText())
  end
  if self.MagicLevelText then
    local tip = ActivityUtils.GetActivityGlobalConfig("activity_grade_tips")
    if tip and not string.IsNilOrEmpty(tip.str) then
      self.MagicLevelText:SetText(string.format(tip.str, _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()))
    else
      self.MagicLevelText:SetText("")
    end
  end
  self:RefreshRewardItems(activityInst)
end

function UMG_Activity_StageAward_C:OnDestruct()
  Base.OnDestruct(self)
  self:UnRegisterEvent(self, ActivityModuleEvent.ConditionRewardItemStatusChange)
  self:UnRegisterEvent(self, ActivityModuleEvent.ConditionRewardItemProgressChange)
  if self.ExchangeStoreBtn then
    self:RemoveButtonListener(self.ExchangeStoreBtn)
  end
end

function UMG_Activity_StageAward_C:OnEnable(firstLoad)
  Base.OnEnable(self, firstLoad)
  if not firstLoad and self.activeItems then
    local activityInst = self.activityInst
    if activityInst and not activityInst:IsActivityInactive() then
      for _index, _ in ipairs(self.activeItems) do
        self.List:OpItemByIndex(_index, RewardItemOpType.Enable)
      end
    end
  end
end

function UMG_Activity_StageAward_C:GetRewardItemIndexByObj(_rewardItemObj)
  local itemIndex = self.List:GetIndexByData(_rewardItemObj, function(_data, _valueInList)
    return _valueInList and _valueInList.customData == _data
  end)
  return itemIndex
end

function UMG_Activity_StageAward_C:RefreshRewardItems(_activityInst)
  if _activityInst and _activityInst == self.activityInst then
    self.activeItems = _activityInst:GetRewardItems(true)
    ActivityUtils.AdjustCtrlAutoSize(self.List, #self.activeItems < 4)
    self.List:InitList(ActivityUtils.CreateActivityItemBaseDataForList(self, self.activeItems))
  end
end

function UMG_Activity_StageAward_C:OnConditionRewardItemStatusChange(_activityInst, _rewardItemObj, _userOperation)
  if _activityInst and _activityInst == self.activityInst then
    local itemIndex = self:GetRewardItemIndexByObj(_rewardItemObj)
    if _userOperation and _rewardItemObj:GetRewardStatus() == ActivityEnum.RewardStatus.Received then
      self.List:OpItemByIndex(itemIndex, RewardItemOpType.RewardReceived)
    else
      self.List:OpItemByIndex(itemIndex, RewardItemOpType.RefreshData)
    end
  end
end

function UMG_Activity_StageAward_C:OnConditionRewardItemProgressChange(_activityInst, _rewardItemObj)
  if _activityInst and _activityInst == self.activityInst then
    local itemIndex = self:GetRewardItemIndexByObj(_rewardItemObj)
    self.List:OpItemByIndex(itemIndex, RewardItemOpType.ProgressChange)
  end
end

function UMG_Activity_StageAward_C:OnItemSelected(_itemInst, _index, _itemObject, _bSelected)
  local activityInst = self.activityInst
  if _bSelected and activityInst then
    local status = _itemObject:GetRewardStatus()
    if status == ActivityEnum.RewardStatus.Available then
      _G.NRCAudioManager:PlaySound2DAuto(41401007, "UMG_Activity_StageAward_C:OnItemSelected")
      activityInst:PerformActivityInteraction(ActivityEnum.ActivityInteractionType.GetReward, _itemObject)
    elseif status == ActivityEnum.RewardStatus.UnAvailable then
      local taskConf = _G.DataConfigManager:GetTaskConf(_itemObject.conf.condition_group[1].condition_param)
      if taskConf then
        local go_guide = taskConf.go_guide[1]
        if go_guide.text then
          _G.NRCModuleManager:DoCmd(go_guide.text, tonumber(go_guide.args), tonumber(go_guide.args2))
        end
      end
    end
  end
end

function UMG_Activity_StageAward_C:OnItemUpdate(_itemInst, _index, _itemObject)
  if not _itemObject then
    return
  end
  _itemObject:UpdateProgress()
  if _itemInst then
    _itemInst:SetDescribe(_itemObject:GetRewardItemDesc())
    _itemInst:SetTitle(_itemObject:GetRewardItemName())
    _itemInst:SetBgImg(_itemObject:GetRewardItemBg())
    _itemInst:SetProgress(_itemObject:GetProgress())
    _itemInst:SetRewardGroup(_itemObject:GetRewardGroup())
    _itemInst:SetupRedPoint(_itemObject:GetRewardRedPointData())
    _itemInst:PlayInAnimation()
  end
  self:OnItemRefreshView(_itemInst, _index, _itemObject)
end

function UMG_Activity_StageAward_C:OnItemRefreshView(_itemInst, _index, _itemObject)
  if not _itemObject then
    return
  end
  if _itemInst then
    local rewardStatus = _itemObject:GetRewardStatus()
    if rewardStatus == ActivityEnum.RewardStatus.UnAvailable then
      local taskConf = _G.DataConfigManager:GetTaskConf(_itemObject.conf.condition_group[1].condition_param)
      if taskConf then
        local go_guide = taskConf.go_guide[1]
        if go_guide.text then
          _itemInst:SetBtnSwitcher(1)
        else
          _itemInst:SetBtnSwitcher(0)
        end
      end
      _itemInst:SetAlreadyReceived(false)
      _itemInst:PlayRewardUnAvailableAnimation()
    elseif rewardStatus == ActivityEnum.RewardStatus.Available then
      _itemInst:SetBtnSwitcher(2)
      _itemInst:SetRewardBtn(false)
      _itemInst:SetAlreadyReceived(false)
      _itemInst:PlayRewardAvailableAnimation()
    elseif rewardStatus == ActivityEnum.RewardStatus.Received then
      _itemInst:SetBtnSwitcher(3)
      _itemInst:SetAlreadyReceived(true)
      _itemInst:PlayRewardReceivedAnimation()
    end
  end
end

function UMG_Activity_StageAward_C:OnItemOp(_itemInst, _index, _itemObject, _opType)
  if not _itemObject then
    return
  end
  if _itemInst then
    if _opType == RewardItemOpType.Enable then
      _itemInst:PlayInAnimation()
      _itemObject:UpdateProgress()
    elseif _opType == RewardItemOpType.RefreshData then
      self:OnItemRefreshView(_itemInst, _index, _itemObject)
    elseif _opType == RewardItemOpType.RewardReceived then
      _itemInst:SetBtnSwitcher(3)
      _itemInst:SetRewardBtn(true)
      _itemInst:SetAlreadyReceived(true)
      _itemInst:PlayRewardGetAnimation()
      local rewardGroup = _itemObject:GetRewardGroup()
      if rewardGroup then
        local rewardsList = {}
        for _, rewardItem in ipairs(rewardGroup) do
          local activityRewardData = ActivityUtils.ParseActivityRewardData(rewardItem.goods_type, rewardItem.goods_id, rewardItem.goods_count)
          local rewardsItemData = {}
          rewardsItemData.type = activityRewardData.itemType
          rewardsItemData.id = activityRewardData.itemId
          rewardsItemData.num = activityRewardData.itemNum
          table.insert(rewardsList, rewardsItemData)
        end
        _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rewardsList, "")
      end
    elseif _opType == RewardItemOpType.ProgressChange then
      _itemInst:SetProgress(_itemObject:GetProgress())
    end
  end
end

function UMG_Activity_StageAward_C:GotoShop()
  local option_id = self.activityInst:GetActivityTypeParam()[1]
  if option_id then
    ActivityUtils.DoActivityOptionCmd(option_id)
  end
end

return UMG_Activity_StageAward_C
