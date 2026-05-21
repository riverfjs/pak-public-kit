local ActivityModuleData = _G.NRCData:Extend("ActivityModuleData")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local JsonUtils = require("Common.JsonUtils")

function ActivityModuleData:Ctor()
  NRCData.Ctor(self)
  self.initFlag = false
  self.cachedActiveActivities = _G.MakeWeakTable({}, "v")
  self.availableInSvrActiveActivities = {}
  self.waitingActiveActivities = {}
  self.inDisplayingActivities = {}
  self.shieldingActivities = {}
  self.waitingConditionActivities = {}
  self.removedActivities = {}
  self.svrActivityBriefInfo = {}
  self.LotteryResultList = {}
  self._CommonOpenTipState = {}
  self.activityAnimFlag = nil
end

function ActivityModuleData:InitClientActiveActivities(serverTime)
  local allActivityConf = _G.DataConfigManager:GetAllByName("ACTIVITY_CONF")
  if not allActivityConf or not next(allActivityConf) then
    return
  end
  local loginChannel, loginPlat
  local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  if accountInfo and accountInfo.plat_info then
    loginChannel = accountInfo.plat_info.cli_login_channel
    loginPlat = accountInfo.plat_info.plat_id
  end
  for _, _conf in pairs(allActivityConf) do
    local enabled = _conf.if_appear
    local loginChannelRequirements = _conf.login_channel
    if enabled and loginChannelRequirements and #loginChannelRequirements > 0 then
      enabled = table.contains(loginChannelRequirements, loginChannel)
    end
    local loginPlatRequirements = _conf.login_plat
    if enabled and loginPlatRequirements and #loginPlatRequirements > 0 then
      enabled = table.contains(loginPlatRequirements, loginPlat)
    end
    if enabled and not string.IsNilOrEmpty(_conf.appear_time) then
      local appear_time = ActivityUtils.ToTimestamp(_conf.appear_time)
      if serverTime < appear_time then
        enabled = false
      end
    end
    if enabled and not string.IsNilOrEmpty(_conf.disappear_time) then
      local disappearTimestamp = ActivityUtils.ToTimestamp(_conf.disappear_time)
      if serverTime >= disappearTimestamp then
        enabled = false
      end
    end
    if enabled and _conf.appear_world_level_require and _conf.appear_world_level_require > 0 then
      local worldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel() or 0
      if worldLevel < _conf.appear_world_level_require then
        enabled = false
        self.waitingConditionActivities[_conf.id] = _conf
      end
    end
    if enabled then
      local activityInst = self:GetOrCreateActivityInst(_conf.id)
      if activityInst then
        table.insert(self.waitingActiveActivities, activityInst)
      end
    end
  end
end

function ActivityModuleData:Init()
  if self.initFlag then
    return false
  end
  local serverTime = ActivityUtils.GetSvrTimestamp()
  if serverTime <= 0 then
    return false
  end
  self.initFlag = true
  self:InitClientActiveActivities(serverTime)
  self:ShieldingActivities(_G.FunctionBanManager:GetSvrShieldingActivities())
  return true
end

function ActivityModuleData:GetOrCreateActivityInst(_activityId)
  local activityInst = self.cachedActiveActivities[_activityId]
  if not activityInst then
    local conf = _G.DataConfigManager:GetActivityConf(_activityId, true)
    local svrBriefInfo = self.svrActivityBriefInfo[_activityId]
    if conf or svrBriefInfo then
      activityInst = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.CreateActivityObject, conf, ActivityEnum.ActivitySource.Svr, svrBriefInfo)
      self.cachedActiveActivities[_activityId] = activityInst
    end
  end
  return activityInst
end

function ActivityModuleData:SetActivitySvrStatus(_activityInst, _enable)
  if not _activityInst then
    return
  end
  local activityId = _activityInst:GetActivityId()
  if _enable then
    _activityInst:SetSvrStatus(ActivityEnum.ActivitySvrStatus.Available)
    self.availableInSvrActiveActivities[activityId] = _activityInst
  else
    _activityInst:SetSvrStatus(ActivityEnum.ActivitySvrStatus.UnAvailable)
    self.availableInSvrActiveActivities[activityId] = nil
  end
end

function ActivityModuleData:GetWaitingActivityInstById(_activityId)
  for _, _inst in ipairs(self.waitingActiveActivities) do
    if _inst:GetActivityId() == _activityId then
      return _inst
    end
  end
end

function ActivityModuleData:AddActivityToWaitingActive(_activityId)
  local alreadyRemoved = false
  if not alreadyRemoved then
    local _activityInst = self:GetWaitingActivityInstById(_activityId)
    if not _activityInst then
      _activityInst = self:GetOrCreateActivityInst(_activityId)
      if _activityInst then
        table.insert(self.waitingActiveActivities, _activityInst)
      end
    end
    self:SetActivitySvrStatus(_activityInst, true)
  end
end

function ActivityModuleData:RefreshActivities()
  if table.isNotEmpty(self.waitingConditionActivities) then
    for _, _activityInst in ipairs(self.waitingActiveActivities) do
      self.waitingConditionActivities[_activityInst:GetActivityId()] = nil
    end
    local worldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel() or 0
    for _activityId, _activityCfg in pairs(self.waitingConditionActivities) do
      if _activityCfg and _activityCfg.appear_world_level_require and worldLevel >= _activityCfg.appear_world_level_require then
        local _activityInst = self:GetOrCreateActivityInst(_activityId)
        if _activityInst then
          table.insert(self.waitingActiveActivities, _activityInst)
        end
      end
    end
    for _, _activityInst in ipairs(self.waitingActiveActivities) do
      self.waitingConditionActivities[_activityInst:GetActivityId()] = nil
    end
  end
  local activateParameter = ActivityUtils.CreateActivityActivateParameter()
  local displayingActivitiesChange = ActivityUtils.RemoveElements(self.inDisplayingActivities, function(_activityInst, _activateParameter)
    _activityInst:RefreshActivityStatus(_activateParameter)
    local showStatus = _activityInst:GetActivityShowStatus()
    if showStatus ~= ActivityEnum.ActivityShowStatus.Enable then
      self.removedActivities[_activityInst:GetActivityId()] = showStatus
      return true
    end
  end, nil, activateParameter)
  if #self.waitingActiveActivities > 0 then
    local _hasNewActiveFlag = false
    for _, _activityInst in ipairs(self.waitingActiveActivities) do
      local _activityId = _activityInst:GetActivityId()
      if not self:GetDisplayActivityInstById(_activityId) then
        if _activityInst then
          _activityInst:SetShieldingStatus(not not self.shieldingActivities[_activityId])
        end
        _activityInst:RefreshActivityStatus(activateParameter)
        local showStatus = _activityInst:GetActivityShowStatus()
        if showStatus == ActivityEnum.ActivityShowStatus.Enable then
          _hasNewActiveFlag = true
          table.insert(self.inDisplayingActivities, _activityInst)
        else
          Log.Warning("activity can not show in client! ", _activityInst:GetActivityId(), showStatus)
        end
      end
    end
    self.waitingActiveActivities = {}
    if _hasNewActiveFlag then
      displayingActivitiesChange = true
      table.sort(self.inDisplayingActivities, function(a, b)
        return a:CompareTo(b)
      end)
    end
  end
  if displayingActivitiesChange then
    local activityModule = self.module
    if activityModule then
      activityModule:DispatchEvent(ActivityModuleEvent.DisplayingActivitiesChange, self.inDisplayingActivities)
    end
  end
end

function ActivityModuleData:SvrUpdateActivities(_svrActivityBriefInfo, _svrActivities)
  if not _svrActivityBriefInfo and not _svrActivities then
    Log.Error("SvrUpdateActivities: _svrActivityBriefInfo and _svrActivities is nil")
    return
  end
  self.svrActivityBriefInfo = {}
  local svrActivityBriefInfo = self.svrActivityBriefInfo
  local svrAvailableActivities = {}
  if _svrActivityBriefInfo then
    for _, _briefInfo in ipairs(_svrActivityBriefInfo) do
      Log.Info("SvrUpdateActivities:", _briefInfo.activity_id)
      svrAvailableActivities[_briefInfo.activity_id] = true
      svrActivityBriefInfo[_briefInfo.activity_id] = _briefInfo
    end
  else
    for _, _activityId in ipairs(_svrActivities) do
      Log.Info("SvrUpdateActivities:", _activityId)
      svrAvailableActivities[_activityId] = true
    end
  end
  local svrUnAvailableActivities = {}
  for _activityId, _ in pairs(self.availableInSvrActiveActivities) do
    if not svrAvailableActivities[_activityId] then
      table.insert(svrUnAvailableActivities, _activityId)
    end
  end
  for _, _activityId in ipairs(svrUnAvailableActivities) do
    self.availableInSvrActiveActivities[_activityId] = nil
  end
  for _, _activityInst in ipairs(self.inDisplayingActivities) do
    local _activityId = _activityInst:GetActivityId()
    if svrAvailableActivities[_activityId] then
      svrAvailableActivities[_activityId] = nil
      self:SetActivitySvrStatus(_activityInst, true)
    else
      self:SetActivitySvrStatus(_activityInst, false)
    end
  end
  for _activityId, _status in pairs(svrAvailableActivities) do
    if _status then
      self:AddActivityToWaitingActive(_activityId)
    end
  end
  self:RefreshActivities()
end

function ActivityModuleData:SvrUpdateActivityStatus(_activityId, _available)
  local _activityInst = self:GetDisplayActivityInstById(_activityId)
  if _activityInst then
    self:SetActivitySvrStatus(_activityInst, _available)
  elseif _available then
    self:AddActivityToWaitingActive(_activityId)
  end
  self:RefreshActivities()
end

function ActivityModuleData:SvrUpdateActivityData(_cmdId, _activityId, _updateData)
  local activityInst = self.availableInSvrActiveActivities[_activityId]
  if activityInst then
    if _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
      local activityData = _updateData
      if activityData.activity_finish_time and activityData.activity_finish_time > 0 then
        activityInst:SetActivityCompleted(activityData.activity_finish_time)
      end
    end
    activityInst:SvrUpdateActivityData(_cmdId, _updateData)
  else
    Log.Warning("Activity is not available now. id: ", _activityId)
  end
end

function ActivityModuleData:ShieldingActivities(_activities)
  local oldShieldingActivities = self.shieldingActivities
  local newShieldingActivities = {}
  local changeRecords = {}
  self.shieldingActivities = newShieldingActivities
  if _activities then
    for _, activityId in ipairs(_activities) do
      newShieldingActivities[activityId] = true
    end
    for activityId, _ in pairs(oldShieldingActivities) do
      if newShieldingActivities[activityId] then
        changeRecords[activityId] = true
      else
        changeRecords[activityId] = 2
      end
    end
    for activityId, _ in pairs(newShieldingActivities) do
      if not oldShieldingActivities[activityId] then
        changeRecords[activityId] = 1
      end
    end
  end
  local hasAnyChange = false
  for activityId, recordValue in pairs(changeRecords) do
    if true ~= recordValue then
      hasAnyChange = true
      local activityInst = self:GetOrCreateActivityInst(activityId)
      if activityInst then
        local mainTabId = activityInst:GetActivityMainTabId()
        local redPointId = ActivityUtils.GetTabRedPoint(mainTabId)
        local activityExtraKeyTable = activityInst:GetTabRedPointExtraKeyList()
        if 1 == recordValue then
          activityInst:SetShieldingStatus(true)
          if activityExtraKeyTable then
            for _, extraKey in ipairs(activityExtraKeyTable) do
              _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.InvalidPointData, redPointId, extraKey)
            end
          end
        elseif 2 == recordValue then
          activityInst:SetShieldingStatus(false)
          if activityExtraKeyTable then
            for _, extraKey in ipairs(activityExtraKeyTable) do
              _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.RecoverPointData, redPointId, extraKey)
            end
          end
          table.insert(self.waitingActiveActivities, activityInst)
        end
      else
        Log.ErrorFormat("ActivityModuleData:ShieldingActivities: activityInst(%d) is nil", activityId)
      end
    end
  end
  if hasAnyChange then
    self:RefreshActivities()
    local activityModule = self.module
    if activityModule then
      activityModule:DispatchEvent(ActivityModuleEvent.ActivitySvrBlockedStateChange)
    end
  end
end

function ActivityModuleData:UploadLocalActivity(_activityInst)
  if not _activityInst then
    return
  end
  local waitingInst = self:GetWaitingActivityInstById(_activityInst:GetActivityId())
  if waitingInst then
    return waitingInst
  end
  table.insert(self.waitingActiveActivities, _activityInst)
  self:RefreshActivities()
  return _activityInst
end

function ActivityModuleData:GetDisplayActivityInstById(_activityId, includeSvrAvailableOnly)
  for _, _activityInst in ipairs(self.inDisplayingActivities) do
    if _activityInst:GetActivityId() == _activityId then
      return _activityInst
    end
  end
  if includeSvrAvailableOnly then
    return self.availableInSvrActiveActivities[_activityId]
  end
end

function ActivityModuleData:GetDisplayActivityInstByType(_activityType, includeSvrAvailableOnly)
  local inst = {}
  for _, _activityInst in ipairs(self.inDisplayingActivities) do
    if _activityInst:GetActivityType() == _activityType then
      table.insert(inst, _activityInst)
    end
  end
  if includeSvrAvailableOnly then
    for _, _activityInst in pairs(self.availableInSvrActiveActivities) do
      if _activityInst:GetActivityType() == _activityType and not table.contains(inst, _activityInst) then
        table.insert(inst, _activityInst)
      end
    end
  end
  return inst
end

function ActivityModuleData:HasDisplayActivities()
  return #self.inDisplayingActivities > 0
end

function ActivityModuleData:GetDisplayActivities()
  return self.inDisplayingActivities
end

function ActivityModuleData:DumpActivityDetail()
  local function GetActivityRedPointReasons()
    local waitProcessRedPointIds = {
      304,
      
      305,
      306
    }
    local processedRedPointIds = {}
    local activityRedPointReasons = {}
    while #waitProcessRedPointIds > 0 do
      local curId = table.remove(waitProcessRedPointIds)
      table.insert(processedRedPointIds, curId)
      local conf = _G.DataConfigManager:GetRedPointConf(curId)
      if conf then
        local reasons = conf.change_reason
        if reasons and #reasons > 0 then
          local reason = reasons[1]
          if not table.contains(activityRedPointReasons, reason) then
            table.insert(activityRedPointReasons, reason)
          end
        end
        local childId = conf.child_id
        if childId then
          for _, _child in ipairs(childId) do
            if not table.contains(processedRedPointIds, _child) and not table.contains(waitProcessRedPointIds, _child) then
              table.insert(waitProcessRedPointIds, _child)
            end
          end
        end
      end
    end
    return activityRedPointReasons
  end
  
  local redPointData = {}
  local redPointModule = NRCModuleManager:GetModule("RedPointModule")
  if redPointModule then
    redPointData = redPointModule:DebugProcessSvrRedPointData()
  end
  local activityRedPointReasons = GetActivityRedPointReasons()
  
  local function DebugActivitiesRedPoint()
    local ret = {}
    for _, reason in pairs(activityRedPointReasons) do
      local pointDebugData = redPointData[reason]
      if pointDebugData then
        if pointDebugData.type == Enum.RedPointType.RPT_AWARD then
          ret[string.format("%d(\229\165\150\229\138\177)", reason)] = pointDebugData
        elseif pointDebugData.type == Enum.RedPointType.RPT_NEW then
          ret[string.format("%d(\230\150\176)", reason)] = pointDebugData
        else
          ret[string.format("%d(\230\143\144\233\134\146)", reason)] = pointDebugData
        end
      end
    end
    return ret
  end
  
  local function SplitString(sourceStr, sep)
    local t = {}
    for str in string.gmatch(sourceStr, "([^" .. sep .. "]+)") do
      table.insert(t, str)
    end
    if 0 == #t then
      table.insert(t, sourceStr)
    end
    return t
  end
  
  local function DebugGetActivityShowStatusStr(_status)
    for _name, _v in pairs(ActivityEnum.ActivityShowStatus) do
      if _v == _status then
        return _name
      end
    end
    return _status
  end
  
  local function GetActivityRedPoint(_activityId)
    local ret = {}
    for _reason, _data in pairs(redPointData) do
      if table.contains(activityRedPointReasons, _reason) then
        for _, _parmaStr in ipairs(_data.pointData) do
          local paramT = SplitString(_parmaStr, "%.")
          if #paramT > 0 and tostring(_activityId) == paramT[1] then
            table.insert(ret, _data)
            break
          end
        end
      end
    end
    return ret
  end
  
  local function DebugFormatTimestamp(_timestamp)
    local detailData = ActivityUtils.ToTimeDetailData(_timestamp)
    return string.format("%04d-%02d-%02d %02d:%02d:%02d", detailData.year, detailData.month, detailData.day, detailData.hour, detailData.minute, detailData.second)
  end
  
  local function DebugWrapActivities(_activities, _showRedPoint)
    local ret = {}
    for _, _activityInst in pairs(_activities) do
      local _data = {}
      _data.id = _activityInst:GetActivityId()
      _data.name = _activityInst:GetActivityName()
      _data.showStatus = DebugGetActivityShowStatusStr(_activityInst:GetActivityShowStatus())
      if _activityInst:GetShieldingStatus() then
        _data.shielding = "\229\177\143\232\148\189\228\184\173"
      end
      local startTime = _activityInst:GetActivityStartTime()
      if 0 ~= startTime then
        _data.startTime = DebugFormatTimestamp(startTime)
      end
      local endTime = _activityInst:GetActivityEndTime()
      if 0 ~= endTime then
        _data.endTime = DebugFormatTimestamp(endTime)
      end
      local completedTimeStamp = _activityInst:GetActivityCompletedTimeStamp()
      if 0 ~= completedTimeStamp then
        _data.completedTimeStamp = DebugFormatTimestamp(completedTimeStamp)
      end
      if _showRedPoint then
        local _activityRedPointData = GetActivityRedPoint(_activityInst:GetActivityId())
        if _activityRedPointData and #_activityRedPointData > 0 then
          _data.redPointData = _activityRedPointData
        end
      end
      ret[string.format("%s(%d)", _data.name, _data.id)] = _data
    end
    return ret
  end
  
  local function DebugRemovedActivities()
    local ret = {}
    for _activityId, _status in pairs(self.removedActivities) do
      if not self:GetDisplayActivityInstById(_activityId) and not self:GetWaitingActivityInstById(_activityId) then
        local activityConf = _G.DataConfigManager:GetActivityConf(_activityId)
        if activityConf then
          ret[string.format("%s(%d)", activityConf.activity_name, _activityId)] = DebugGetActivityShowStatusStr(_status)
        else
          ret[tostring(_activityId)] = DebugGetActivityShowStatusStr(_status)
        end
      end
    end
    return ret
  end
  
  local function DebugClientFilterActivities()
    local svrActivities = {}
    for _id, _inst in pairs(self.availableInSvrActiveActivities) do
      svrActivities[_id] = _inst
    end
    for _, _inst in ipairs(self.inDisplayingActivities) do
      svrActivities[_inst:GetActivityId()] = nil
    end
    for _, _inst in ipairs(self.waitingActiveActivities) do
      svrActivities[_inst:GetActivityId()] = nil
    end
    return DebugWrapActivities(svrActivities, true)
  end
  
  local function DebugClientPreviewActivities()
    local svrActivities = {}
    for _, _inst in ipairs(self.inDisplayingActivities) do
      svrActivities[_inst:GetActivityId()] = _inst
    end
    for _, _inst in ipairs(self.waitingActiveActivities) do
      svrActivities[_inst:GetActivityId()] = _inst
    end
    for _, _inst in pairs(self.availableInSvrActiveActivities) do
      svrActivities[_inst:GetActivityId()] = nil
    end
    local remainActivities = table.copy(svrActivities)
    for _id, _inst in pairs(remainActivities) do
      local activityType = _inst:GetActivityType()
      if activityType < 0 then
        svrActivities[_id] = nil
      end
    end
    return DebugWrapActivities(svrActivities, true)
  end
  
  local function DebugShieldingActivities()
    local ret = {}
    for activityId, shielding in pairs(self.shieldingActivities) do
      if shielding then
        local activityConf = _G.DataConfigManager:GetActivityConf(activityId)
        table.insert(ret, string.format("%s(%d)", activityConf and activityConf.activity_name or "", activityId))
      end
    end
    return ret
  end
  
  local function DebugOtherInfo()
    local DebugData = {}
    local loginChannel, loginPlat
    local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if accountInfo and accountInfo.plat_info then
      loginChannel = accountInfo.plat_info.cli_login_channel
      loginPlat = accountInfo.plat_info.plat_id
    end
    for str, v in pairs(Enum.CliLoginChannel) do
      if v == loginChannel then
        DebugData["\231\153\187\229\189\149\230\184\160\233\129\147"] = str
        break
      end
    end
    for str, v in pairs(Enum.PlatType) do
      if v == loginPlat then
        DebugData["\231\153\187\229\189\149\229\185\179\229\143\176"] = str
        break
      end
    end
    DebugData["\230\156\141\229\138\161\229\153\168\230\151\182\233\151\180"] = DebugFormatTimestamp(ActivityUtils.GetSvrTimestamp())
    return DebugData
  end
  
  local DebugData = {
    ["\230\180\187\229\138\168\231\186\162\231\130\185\230\177\135\230\128\187"] = DebugActivitiesRedPoint(),
    ["\230\156\141\229\138\161\229\153\168\228\184\138\230\158\182\231\154\132\230\180\187\229\138\168"] = DebugWrapActivities(self.availableInSvrActiveActivities, true),
    ["\231\173\137\229\190\133\229\177\149\231\164\186\231\154\132\230\180\187\229\138\168\229\136\151\232\161\168"] = DebugWrapActivities(self.waitingActiveActivities),
    ["\229\174\162\230\136\183\231\171\175\230\143\144\229\137\141\229\177\149\231\164\186\231\154\132\230\180\187\229\138\168\229\136\151\232\161\168"] = DebugClientPreviewActivities(),
    ["\229\177\149\231\164\186\228\184\173\231\154\132\230\180\187\229\138\168\229\136\151\232\161\168"] = DebugWrapActivities(self.inDisplayingActivities, true),
    ["\229\183\178\228\184\139\230\158\182\231\154\132\230\180\187\229\138\168"] = DebugRemovedActivities(),
    ["\229\174\162\230\136\183\231\171\175\232\191\135\230\187\164\231\154\132\230\180\187\229\138\168"] = DebugClientFilterActivities(),
    ["\229\177\143\232\148\189\228\184\173\231\154\132\230\180\187\229\138\168\229\136\151\232\161\168"] = DebugShieldingActivities(),
    ["\229\133\182\229\174\131\228\191\161\230\129\175"] = DebugOtherInfo()
  }
  do
    local DebugData_classifyActivities = {
      [ActivityEnum.ActivityTypeSpecial.PandoraActivity] = {
        name = "\229\177\149\231\164\186\231\154\132\230\189\152\229\164\154\230\139\137\230\180\187\229\138\168\229\136\151\232\161\168",
        activities = {}
      }
    }
    for _, _inst in ipairs(self.inDisplayingActivities) do
      local activityType = _inst:GetActivityType()
      local classify = DebugData_classifyActivities[activityType]
      if classify then
        table.insert(classify.activities, _inst)
      end
    end
    for _, classify in pairs(DebugData_classifyActivities) do
      if classify and #classify.activities > 0 then
        DebugData[classify.name] = DebugWrapActivities(classify.activities, true)
      end
    end
  end
  local DebugDataRet = {}
  for k, v in pairs(DebugData) do
    local cnt = table.len(v)
    DebugDataRet[string.format("%s(%d)", k, cnt)] = v
  end
  return DebugDataRet
end

local _ActivityAnimFlagFileName = "NrcActivityAnimFlag"

function ActivityModuleData:LoadActivityAnimFlag()
  self.activityAnimFlag = JsonUtils.LoadSaved(_ActivityAnimFlagFileName, {})
end

function ActivityModuleData:SaveActivityAnimFlag()
  if self.activityAnimFlag then
    JsonUtils.DumpSaved(_ActivityAnimFlagFileName, self.activityAnimFlag)
  end
end

return ActivityModuleData
