local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ConditionRewardHandler = {}
local RewardItemStatus = {
  Locked = 0,
  Completed = 1,
  Done = 2
}

local function CreateProgressAsyncQueryStruct(_rewardItemObj, _customData)
  local asyncQueryStruct = {}
  asyncQueryStruct.callback = _G.MakeWeakFunctor(_rewardItemObj, _rewardItemObj.OnUpdateProgressCallback)
  asyncQueryStruct.customData = _customData
  return asyncQueryStruct
end

local function ProcessTaskInfo(_taskInfo, _taskTargetNum)
  if _taskInfo and _taskInfo.state ~= ProtoEnum.EMTaskState.EM_TASK_STATE_CLOSED then
    if _taskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
      return _taskTargetNum, _taskInfo.state
    elseif _taskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
      return _taskTargetNum, _taskInfo.state
    elseif _taskTargetNum > 1 and _taskInfo.task_target_list and #_taskInfo.task_target_list > 0 then
      local finishCnt = _taskInfo.task_target_list[1]
      if finishCnt > 0 then
        return finishCnt, _taskInfo.state
      end
    end
  end
end

local ConditionRewardProgressQueryHandlers = {
  [Enum.RequiredType.ACTRT_LEVEL] = function(_param, _rewardItemObj)
    return _G.DataModelMgr.PlayerDataModel:GetPlayerLevel(), _param
  end,
  [Enum.RequiredType.ACTRT_WORLD_LEVEL] = function(_param, _rewardItemObj)
    return _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel(), _param
  end,
  [Enum.RequiredType.ACTRT_TASK] = function(_param, _rewardItemObj)
    local taskTargetNum = 1
    if _param and 0 ~= _param then
      local taskConf = _G.DataConfigManager:GetTaskConf(_param)
      if taskConf and taskConf.task_condition and #taskConf.task_condition > 0 then
        local taskConditionCnt = taskConf.task_condition[1].count
        if taskConditionCnt and taskConditionCnt > 0 then
          taskTargetNum = taskConditionCnt
        end
      end
      local taskObj = _G.TaskModuleCmd and _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.getTaskByID, _param)
      if taskObj then
        local finishCnt, customData = ProcessTaskInfo(taskObj, taskTargetNum)
        return finishCnt, taskTargetNum, customData
      end
      local asyncQueryStruct = CreateProgressAsyncQueryStruct(_rewardItemObj, _param)
      
      local function OnZoneTaskQueryRsp(_asyncQueryStruct, _protoData)
        if _asyncQueryStruct then
          if not _protoData or 0 ~= _protoData.ret_info.ret_code then
            Log.ErrorFormat("[OnZoneTaskQueryRsp] failed! taskId=%s", tostring(_asyncQueryStruct.customData))
            return
          end
          local taskInfoList = _protoData.task_info_list
          if taskInfoList then
            for _, _taskInfo in ipairs(taskInfoList) do
              if _taskInfo.id == _asyncQueryStruct.customData then
                local finishCnt, customData = ProcessTaskInfo(_taskInfo, taskTargetNum)
                if finishCnt then
                  _asyncQueryStruct.callback(finishCnt, taskTargetNum, customData)
                end
                return
              end
            end
          end
        end
      end
      
      local req = _G.ProtoMessage:newZoneTaskQueryReq()
      req.task_list = {_param}
      req.task_state = 0
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, asyncQueryStruct, OnZoneTaskQueryRsp)
    end
    return nil, taskTargetNum
  end,
  [Enum.RequiredType.ACTRT_LOGIN_DAY_TOTAL] = function(_param, _rewardItemObj)
    return _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetLoginDays), _param
  end,
  [Enum.RequiredType.ACTRT_PVP_RANK] = function(_param, _rewardItemObj)
    return _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_PVP_RANK_STAR), _param
  end,
  [Enum.RequiredType.ACTRT_HANDBOOK_NUM] = function(_param, _rewardItemObj)
    local areaInfo = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetAreaHandbookInfo, Enum.AreaHandbookType.AHT_KINGDOM)
    if areaInfo then
      return areaInfo.collect_coll_num, _param
    end
    return 0, _param
  end,
  [Enum.RequiredType.ACTRT_EQUIPMENT] = function(_param, _rewardItemObj)
    if 1 == _param and RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
      return 1, 1
    elseif 2 == _param and RocoEnv.PLATFORM ~= "PLATFORM_WINDOWS" then
      return 1, 1
    end
    return 0, 1
  end,
  [Enum.RequiredType.ACTRT_ACTIVITY_LOGIN_DAY] = function(_param, _rewardItemObj)
    local owner = _rewardItemObj and _rewardItemObj:GetOwner()
    if owner and owner.GetActivityLoginDays then
      return owner:GetActivityLoginDays(), _param
    end
    return 0, _param
  end,
  [Enum.RequiredType.ACTRT_LOGIN_DAY_TOTAL_SPEC] = function(_param, _rewardItemObj)
    local loginDays = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetLoginDays)
    local owner = _rewardItemObj and _rewardItemObj:GetOwner()
    if owner and owner.GetLoginAccelerateDays then
      loginDays = loginDays + owner:GetLoginAccelerateDays()
    end
    return loginDays, _param
  end
}
local ConditionRewardItemObjectBase = Class("ConditionRewardItemObjectBase")

function ConditionRewardItemObjectBase:Ctor(_owner, _conditionEnum, _conditionParam, ...)
  assert(_owner and type(_owner) == "table", "owner must be a valid table")
  assert(_conditionEnum and type(_conditionEnum) == "number", "conditionEnum must be a valid number")
  self.owner = _owner
  self.status = RewardItemStatus.Locked
  self.curProgress = 0
  self.totalProgress = 0
  self.conditionEnum = _conditionEnum
  self.conditionCustomData = nil
  self.progressQueryParam = _conditionParam
  self.progressQueryHandler = ConditionRewardProgressQueryHandlers[_conditionEnum]
  if not self.progressQueryHandler then
    Log.ErrorFormat("not support RequiredType=%d", _conditionEnum)
  end
  if self.OnConstruct then
    self:OnConstruct(...)
  end
end

function ConditionRewardItemObjectBase:TriggerRewardItemProgressChange()
  if self.owner and self.owner.OnRewardItemProgressChange then
    self.owner:OnRewardItemProgressChange(self)
  end
end

function ConditionRewardItemObjectBase:TriggerRewardItemStatusChange(_userOperation)
  if self.owner and self.owner.OnRewardItemStatusChange then
    self.owner:OnRewardItemStatusChange(self, _userOperation or false)
  end
end

function ConditionRewardItemObjectBase:GetOwner()
  return self.owner
end

function ConditionRewardItemObjectBase:GetConditionEnum()
  return self.conditionEnum
end

function ConditionRewardItemObjectBase:GetConditionParam()
  return self.progressQueryParam
end

function ConditionRewardItemObjectBase:GetConditionCustomData()
  return self.conditionCustomData
end

function ConditionRewardItemObjectBase:GetProgress()
  if not self.curProgress then
    self:UpdateProgress()
  end
  if self.status ~= RewardItemStatus.Locked then
    return self.totalProgress, self.totalProgress, self.conditionEnum
  end
  return self.curProgress, self.totalProgress, self.conditionEnum
end

function ConditionRewardItemObjectBase:UpdateProgress()
  if self.progressQueryHandler and (self.status == RewardItemStatus.Locked or self.totalProgress <= 0) then
    local cur, total, customData = self.progressQueryHandler(self.progressQueryParam, self)
    self.totalProgress = total or 1
    self:OnUpdateProgressCallback(cur, total, customData)
  end
end

function ConditionRewardItemObjectBase:OnUpdateProgressCallback(_cur, _total, _customData)
  self.conditionCustomData = _customData
  if _cur then
    local preCur = self.curProgress or 0
    self.curProgress = _cur
    if preCur ~= _cur then
      self:TriggerRewardItemProgressChange()
    end
  end
end

function ConditionRewardItemObjectBase:SetRewardReceived(_userOperation)
  if self.status == RewardItemStatus.Done then
    return
  end
  self.status = RewardItemStatus.Done
  self:TriggerRewardItemStatusChange(_userOperation)
end

function ConditionRewardItemObjectBase:SetCompleted(_userOperation)
  if self.status == RewardItemStatus.Completed then
    return
  end
  self.status = RewardItemStatus.Completed
  self:TriggerRewardItemStatusChange(_userOperation)
  self:TriggerRewardItemProgressChange()
end

function ConditionRewardItemObjectBase:ResetStatus()
  if self.status ~= RewardItemStatus.Locked then
    self.status = RewardItemStatus.Locked
    self:TriggerRewardItemStatusChange(false)
    self:TriggerRewardItemProgressChange()
  end
end

function ConditionRewardItemObjectBase:GetRewardStatus()
  if self.status == RewardItemStatus.Completed then
    return ActivityEnum.RewardStatus.Available
  elseif self.status == RewardItemStatus.Done then
    return ActivityEnum.RewardStatus.Received
  end
  return ActivityEnum.RewardStatus.UnAvailable
end

local ConditionRewardItemObject = ConditionRewardItemObjectBase:Extend("ConditionRewardItemObject")

function ConditionRewardItemObject:OnConstruct(_conf)
  self.conf = _conf
end

function ConditionRewardItemObject:GetRewardItemId()
  return self.conf.id
end

function ConditionRewardItemObject:GetRewardItemName()
  return self.conf.part_name
end

function ConditionRewardItemObject:GetRewardItemDesc()
  return self.conf.part_desc
end

function ConditionRewardItemObject:GetRewardItemBg()
  return self.conf.part_img, self.conf.part_img_success
end

function ConditionRewardItemObject:NeedTobeLastIfRewardReceived()
  return self.conf.is_realign_end
end

function ConditionRewardItemObject:GetRewardGroup()
  return self.conf.reward_group
end

function ConditionRewardItemObject:GetRewardRedPointData()
  if self.owner then
    return ActivityEnum.RedPointKey.DetailReward, {
      self.owner:GetActivityId(),
      self:GetRewardItemId()
    }
  end
end

function ConditionRewardHandler.CreateExtendCls(name)
  return ConditionRewardItemObjectBase:Extend(name)
end

function ConditionRewardHandler.CreateVariableExtendCls(cls)
  local VariableConditionItemObject = cls or {}
  
  function VariableConditionItemObject.__index(t, k)
    local mt = getmetatable(t)
    if mt then
      local v = mt[k]
      if v then
        return v
      end
    end
    local conditionObject = rawget(t, "conditionObject")
    if conditionObject then
      return conditionObject[k]
    end
  end
  
  function VariableConditionItemObject.__newindex(t, k, v)
    local conditionObject = rawget(t, "conditionObject")
    if conditionObject and conditionObject[k] then
      conditionObject[k] = v
    else
      rawset(t, k, v)
    end
  end
  
  setmetatable(VariableConditionItemObject, {
    __call = function(_cls, ...)
      local instance = {}
      setmetatable(instance, VariableConditionItemObject)
      instance:Ctor(...)
      return instance
    end
  })
  
  function VariableConditionItemObject:Ctor(owner, conditionEnum, conditionParam, ...)
    self.conditionObject = ConditionRewardHandler.CreateExtendClsInstance(nil, owner, conditionEnum, conditionParam)
    if self.OnConstruct then
      self:OnConstruct(...)
    end
  end
  
  function VariableConditionItemObject:ChangeCondition(conditionEnum, conditionParam)
    if conditionEnum ~= self:GetConditionEnum() or conditionParam ~= self:GetConditionParam() then
      local owner = self:GetOwner()
      self.conditionObject = ConditionRewardHandler.CreateExtendClsInstance(nil, owner, conditionEnum, conditionParam)
      if owner and owner.OnRewardItemConditionChange then
        owner:OnRewardItemConditionChange(self)
      end
    end
  end
  
  return VariableConditionItemObject
end

function ConditionRewardHandler.CreateExtendClsInstance(cls, _owner, _conditionEnum, _conditionParam, ...)
  cls = cls or ConditionRewardItemObjectBase
  return cls(_owner, _conditionEnum, _conditionParam, ...)
end

function ConditionRewardHandler.CreateConditionRewardItemObject(_owner, _rewardConf)
  local conditionGroup = _rewardConf and _rewardConf.condition_group
  if conditionGroup and #conditionGroup > 0 then
    local condition = conditionGroup[1]
    return ConditionRewardHandler.CreateExtendClsInstance(ConditionRewardItemObject, _owner, condition.condition_enum, condition.condition_param, _rewardConf)
  else
    Log.Error("ConditionRewardHandler.CreateConditionRewardItemObject: _rewardConf is invalid!")
  end
end

return ConditionRewardHandler
