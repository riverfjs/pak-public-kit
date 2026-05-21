local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityConditionRewardHandler = require("NewRoco.Modules.System.Activity.ActivityObject.ConditionRewardHandler")
local ConditionRewardActivityObject = Base:Extend("ConditionRewardActivityObject")

function ConditionRewardActivityObject:OnConstruct(_conf)
  self.rewardItems = {}
  self.rewardItemMap = _G.MakeWeakTable({}, "v")
  local partIds = self:GetPartIds()
  if partIds and #partIds > 0 then
    for _, partId in ipairs(partIds) do
      local itemObject = ActivityConditionRewardHandler.CreateConditionRewardItemObject(self, _G.DataConfigManager:GetActivityConditionRewardConf(partId))
      table.insert(self.rewardItems, itemObject)
      self.rewardItemMap[partId] = itemObject
    end
  end
end

function ConditionRewardActivityObject:GetRewardItems(_uniqueData)
  local rewardItems = self.rewardItems
  if not rewardItems then
    return
  end
  self:SortObject(rewardItems, function(a, b)
    local a_status = a:GetRewardStatus()
    local b_status = b:GetRewardStatus()
    if a_status == b_status then
      return a.conf.condition_group[1].condition_param > b.conf.condition_group[1].condition_param
    elseif b_status == ActivityEnum.RewardStatus.Available then
      return true
    elseif b_status == ActivityEnum.RewardStatus.UnAvailable and a_status == ActivityEnum.RewardStatus.Received then
      return true
    else
      return false
    end
  end, 1, #rewardItems)
  return _uniqueData and ActivityUtils.ShallowCopyElements(rewardItems) or rewardItems
end

function ConditionRewardActivityObject:SortObject(data, func, start, stop)
  if stop <= start then
    return
  end
  local baseItem = data[start]
  local left = start
  local right = stop
  local bRight = true
  while left < right do
    if bRight then
      if func(baseItem, data[right]) then
        data[left] = data[right]
        left = left + 1
        bRight = false
      else
        right = right - 1
      end
    elseif func(data[left], baseItem) then
      data[right] = data[left]
      right = right - 1
      bRight = true
    else
      left = left + 1
    end
  end
  data[left] = baseItem
  self:SortObject(data, func, start, left - 1)
  self:SortObject(data, func, left + 1, stop)
end

function ConditionRewardActivityObject:GetRewardItem(_partId)
  return self.rewardItemMap[_partId]
end

function ConditionRewardActivityObject:OnRewardItemStatusChange(_itemObj, _userOperation)
  if _itemObj then
    self:SendEvent(ActivityModuleEvent.ConditionRewardItemStatusChange, self, _itemObj, _userOperation)
  end
end

function ConditionRewardActivityObject:OnRewardItemProgressChange(_itemObj)
  if _itemObj then
    self:SendEvent(ActivityModuleEvent.ConditionRewardItemProgressChange, self, _itemObj)
  end
end

function ConditionRewardActivityObject:OnZoneReceivePlayerActivityConditionRewardRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  if not _req or _req.activity_id ~= self:GetActivityId() then
    Log.Error("parameter error!")
    return
  end
  if 0 == _req.activity_part_id then
    for i, v in pairs(self.rewardItemMap) do
      if v and v:GetRewardStatus() == ActivityEnum.RewardStatus.Available then
        v:SetRewardReceived(true)
      end
    end
  else
    local itemObj = self:GetRewardItem(_req.activity_part_id)
    if itemObj then
      itemObj:SetRewardReceived(true)
    else
      Log.Error("Can not find reward item: part_id=", _req.activity_part_id)
    end
  end
  _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.GetConditionRewardItemRewardSuccess, _protoData.ret_info.goods_reward)
end

function ConditionRewardActivityObject:SyncActivityDataOnAvailable()
  self:ReqGetPlayerActivityData()
end

function ConditionRewardActivityObject:OnSvrUpdateActivityData(_cmdId, _updateData, _initUpdate)
  if _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    self.svrActivityData = _updateData
    local _activityData = _updateData
    self.activity_open_time = _activityData.activity_open_time
    local partData = _activityData.part_data
    if partData then
      for _, _partDataEntry in ipairs(partData) do
        local _itemObj = self:GetRewardItem(_partDataEntry.activity_part_id)
        if _itemObj then
          if _partDataEntry.state == _G.ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_WAIT then
            _itemObj:SetCompleted(false)
          elseif _partDataEntry.state == _G.ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_DONE then
            _itemObj:SetRewardReceived(false)
          else
            _itemObj:ResetStatus()
          end
        end
      end
    end
  elseif _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_ADD_PLAYER_ACTIVITY_PART_REWARD_NTY then
    local _partId = _updateData
    local itemObj = self:GetRewardItem(_partId)
    if itemObj then
      itemObj:SetCompleted(true)
    end
  end
  local viewPanel = self.weakRef.viewPanel
  if viewPanel and viewPanel.OnSvrUpdateActivityData then
    local _activityData = _updateData
    viewPanel:OnSvrUpdateActivityData(_cmdId, _activityData, _initUpdate)
  end
end

function ConditionRewardActivityObject:OnTryGetReward(_itemObj, partId)
  if _itemObj then
    local rewardStatus = _itemObj:GetRewardStatus()
    if rewardStatus == ActivityEnum.RewardStatus.Available then
      local req = _G.ProtoMessage:newZoneReceivePlayerActivityConditionRewardReq()
      req.activity_id = self:GetActivityId()
      req.activity_part_id = partId or _itemObj:GetRewardItemId()
      ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_CONDITION_REWARD_REQ, req, self, self.OnZoneReceivePlayerActivityConditionRewardRsp)
    end
    return rewardStatus
  end
end

function ConditionRewardActivityObject:OnTryGetLoginPartReward(_itemObj)
  if _itemObj then
    local rewardStatus = _itemObj:GetRewardStatus()
    if rewardStatus == ActivityEnum.RewardStatus.Available then
      local req = _G.ProtoMessage:newZoneReceivePlayerActivityPartRewardReq()
      req.activity_id = self:GetActivityId()
      req.activity_part_id = _itemObj:GetRewardItemId()
      ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_PART_REWARD_REQ, req, self, self.OnZoneReceivePlayerActivityPartRewardRsp)
    end
  end
end

function ConditionRewardActivityObject:OnZoneReceivePlayerActivityPartRewardRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  if not _req or _req.activity_id ~= self:GetActivityId() then
    return
  end
  local itemObj = self:GetRewardItem(_req.activity_part_id)
  if itemObj then
    itemObj:SetRewardReceived(true)
  else
    Log.Error("Can not find reward item: part_id=", _req.activity_part_id)
  end
  self:SendEvent(ActivityModuleEvent.ConditionRewardItemProgressChange, self, itemObj)
  if #((_protoData.ret_info.goods_reward or {}).rewards or {}) > 0 then
    local CommonPopUpData
    if ActivityUtils.ShowRewardChoose(_protoData.ret_info, true) then
      CommonPopUpData = _G.NRCCommonPopUpData()
      CommonPopUpData.HideBtn = false
      CommonPopUpData.OnlyHideRightBtn = true
      CommonPopUpData.Call = self
      
      function CommonPopUpData.Btn_LeftHandler()
        ActivityUtils.ShowRewardChoose(_protoData.ret_info)
        _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.CloseNPCShopItemRewardsPanel)
      end
    end
    _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, _protoData.ret_info.goods_reward.rewards, "", nil, nil, nil, nil, nil, CommonPopUpData)
  end
end

function ConditionRewardActivityObject:GetShowIllustration()
  local baseIds = self:GetPartIds()
  if baseIds then
    for i, v in ipairs(baseIds) do
      local conf = _G.DataConfigManager:GetActivityConditionRewardConf(v, true)
      if conf and conf.is_show_item then
        return conf.show_img
      end
    end
  end
  return ""
end

return ConditionRewardActivityObject
