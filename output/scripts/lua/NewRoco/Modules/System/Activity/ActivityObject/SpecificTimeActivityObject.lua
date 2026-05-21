local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local SpecificTimeActivityObject = Base:Extend("SpecificTimeActivityObject")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")

function SpecificTimeActivityObject:OnConstruct(_conf)
  local activityId = self:GetActivityId()
  Log.Error("SpecificTimeActivityObject:OnConstruct*------------", activityId)
  self:AddActivityExpiredCallback("SpecificTimeActivityOver", nil, function()
    _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.OnSpecificTimeActivityOver, activityId)
  end)
end

function SpecificTimeActivityObject:SyncActivityDataOnAvailable()
  self:ReqGetPlayerActivityData()
end

function SpecificTimeActivityObject:OnDestruct()
end

function SpecificTimeActivityObject:OnSvrUpdateActivityData(_cmdId, _updateData, _initUpdate)
  if _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    local lastReachLimitMap = self:GetAllMethodReachLimit()
    local lastIsReachLimit = self:IsReachLimit()
    local _activityData = _updateData
    self.activityDropData = _activityData and _activityData.drop_data
    self:SendEvent(ActivityModuleEvent.RefreshActivityDropData, self:GetActivityId(), self.activityDropData)
    if not _initUpdate then
      local curIsReachLimit = self:IsReachLimit()
      if not lastIsReachLimit and curIsReachLimit then
        _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.OnSpecificTimeActivityDropUpperLimit, self:GetActivityId())
      end
      local curReachLimitMap = self:GetAllMethodReachLimit()
      for i, v in pairs(curReachLimitMap) do
        if not lastReachLimitMap[i] and v then
          _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.OnSpecificTimeActivityDropUpperLimit, self:GetActivityId(), i)
        end
      end
    end
  end
end

function SpecificTimeActivityObject:GetAllMethodReachLimit()
  local lastIsReachLimitMap = {}
  local allDropConf = self:GetAllActivityDropConf()
  for idx, dropConf in ipairs(allDropConf) do
    if dropConf and dropConf.drop_id then
      for i, methodId in pairs(dropConf.drop_id) do
        if methodId and nil == lastIsReachLimitMap[methodId] then
          lastIsReachLimitMap[methodId] = self:SingleMethodIsReachLimit(methodId)
        end
      end
    end
  end
  return lastIsReachLimitMap
end

function SpecificTimeActivityObject:IsReachLimit()
  local activityDropData = self.activityDropData
  local allDropConf = self:GetAllActivityDropConf()
  if not allDropConf or 0 == #allDropConf then
    return true
  end
  for idx, dropConf in ipairs(allDropConf) do
    local dailyAlreadyGet = 0
    local totalAlreadyGet = 0
    if activityDropData and activityDropData.method_drop_list then
      for i, v in pairs(activityDropData.method_drop_list) do
        if v.drop_item_list then
          for j, k in pairs(v.drop_item_list) do
            if k.item_id == dropConf.goods_id then
              dailyAlreadyGet = dailyAlreadyGet + k.item_num_today
              totalAlreadyGet = totalAlreadyGet + k.item_num_total
            end
          end
        end
      end
    end
    local bReach = dailyAlreadyGet >= dropConf.day_got_limit or totalAlreadyGet >= dropConf.total_got_limit
    if not bReach then
      return false
    end
  end
  return true
end

function SpecificTimeActivityObject:SingleMethodIsReachLimit(methodId)
  if not methodId then
    Log.Error("SpecificTimeActivityObject:SingleMethodIsReachLimit methodId is nil")
    return true
  end
  local activityDropData = self.activityDropData
  local methodConf = _G.DataConfigManager:GetActivityDropMethodConf(methodId)
  local getCntMap = {}
  local limitCntNap = {}
  if activityDropData and activityDropData.method_drop_list then
    for i, v in pairs(activityDropData.method_drop_list) do
      if methodId == v.method_id then
        if v.reach_daily_limit then
          return true
        end
        if v.drop_item_list then
          for j, k in pairs(v.drop_item_list) do
            if not getCntMap[k.item_id] then
              getCntMap[k.item_id] = {}
            end
            getCntMap[k.item_id].dayLimit = (getCntMap[k.item_id].dayLimit or 0) + k.item_num_today
            getCntMap[k.item_id].totalLimit = (getCntMap[k.item_id].totalLimit or 0) + k.item_num_total
          end
        end
      end
    end
  end
  if methodConf and methodConf.reward_group then
    for i, v in pairs(methodConf.reward_group) do
      if not limitCntNap[v.goods_id] then
        limitCntNap[v.goods_id] = {}
      end
      limitCntNap[v.goods_id].dayLimit = v.day_got_limit
      limitCntNap[v.goods_id].totalLimit = v.total_got_limit
    end
  end
  for i, v in pairs(limitCntNap) do
    if getCntMap[i] then
      if getCntMap[i].dayLimit < v.dayLimit and getCntMap[i].totalLimit < v.totalLimit then
        return false
      end
    else
      return false
    end
  end
  return true
end

function SpecificTimeActivityObject:GetActivityDropConf()
  local allDropConf = self:GetAllActivityDropConf()
  return allDropConf[1]
end

function SpecificTimeActivityObject:GetActivityDropData()
  return self.activityDropData
end

function SpecificTimeActivityObject:GetTrackTypeAndParams()
  local allDropConf = self:GetAllActivityDropConf()
  if allDropConf and allDropConf[1] then
    return allDropConf[1].track_type, allDropConf[1].track_type_param
  end
end

function SpecificTimeActivityObject:GetAlreadyGetNum()
  local activityDropData = self.activityDropData
  local dropConf = self:GetActivityDropConf()
  local dailyAlreadyGet = 0
  local totalAlreadyGet = 0
  if activityDropData and activityDropData.method_drop_list then
    for i, v in pairs(activityDropData.method_drop_list) do
      if v.drop_item_list then
        for j, k in pairs(v.drop_item_list) do
          if k.item_id == dropConf.goods_id then
            dailyAlreadyGet = dailyAlreadyGet + k.item_num_today
            totalAlreadyGet = totalAlreadyGet + k.item_num_total
          end
        end
      end
    end
  end
  return dailyAlreadyGet, totalAlreadyGet
end

function SpecificTimeActivityObject:CanShowDropReward(type)
  local allDropConf = self:GetAllActivityDropConf()
  for idx, dropConf in ipairs(allDropConf) do
    if dropConf and dropConf.drop_id and #dropConf.drop_id > 0 then
      for i, v in ipairs(dropConf.drop_id) do
        local dropMetConf = _G.DataConfigManager:GetActivityDropMethodConf(v, true)
        if dropMetConf then
          if dropMetConf.drop_show_area and dropMetConf.drop_show_area ~= type then
            return false
          end
          local curTime = ActivityUtils.GetSvrTimestamp()
          local starTime = ActivityUtils.ToTimestamp(dropMetConf.begin_time)
          local endTime = ActivityUtils.ToTimestamp(dropMetConf.end_time)
          if not (0 == starTime or curTime >= starTime) or 0 ~= endTime and not (curTime < endTime) then
            return false
          end
          if self:SingleMethodIsReachLimit(v) then
            return false
          end
          if self:IsReachLimit() then
            return false
          end
          return true, v
        end
      end
    end
  end
  return false
end

function SpecificTimeActivityObject:GetAllActivityDropConf()
  if self.allActivityDropConf then
    return self.allActivityDropConf
  end
  local partIds = self:GetPartIds()
  self.allActivityDropConf = table.new(#partIds)
  for idx, partId in ipairs(partIds) do
    local activityDropConf = _G.DataConfigManager:GetActivityDropConf(partId, true)
    table.insert(self.allActivityDropConf, activityDropConf)
  end
  return self.allActivityDropConf
end

function SpecificTimeActivityObject:GetAlreadyGetNumByTypeAndId(itemType, itemId)
  if not itemType or not itemId then
    return
  end
  local activityDropData = self.activityDropData
  local dailyAlreadyGet = 0
  local totalAlreadyGet = 0
  if activityDropData and activityDropData.method_drop_list then
    for i, v in pairs(activityDropData.method_drop_list) do
      if v.drop_item_list then
        for j, k in pairs(v.drop_item_list) do
          if k.item_type == itemType and k.item_id == itemId then
            dailyAlreadyGet = dailyAlreadyGet + k.item_num_today
            totalAlreadyGet = totalAlreadyGet + k.item_num_total
          end
        end
      end
    end
  end
  return dailyAlreadyGet, totalAlreadyGet
end

return SpecificTimeActivityObject
