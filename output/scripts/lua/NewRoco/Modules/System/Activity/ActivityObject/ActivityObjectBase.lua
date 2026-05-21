local Class = _G.MakeSimpleClass
local ActivityObjectBase = Class("ActivityObjectBase")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local AttrBindingUtils = require("NewRoco.Modules.System.Activity.AttrBinding.AttrBindingUtils")
local TaskQueryHandler = require("NewRoco.Modules.System.Misc.TaskQueryHandler")
local ActivityObjectClassData = {}

local function SetActivityObjectClassData(activityInst, key, value)
  local cls = ActivityObjectClassData[activityInst:GetActivityType()]
  if not cls then
    cls = {}
    ActivityObjectClassData[activityInst:GetActivityType()] = cls
  end
  cls[key] = value
end

local function GetActivityObjectClassData(activityInst, key)
  local cls = ActivityObjectClassData[activityInst:GetActivityType()]
  if cls then
    return cls[key]
  end
end

ActivityObjectBase:SetMemberCount(32)

function ActivityObjectBase:Ctor(_conf, ...)
  self.activityConf = _conf or {}
  self.status = ActivityEnum.ActivityStatus.WaitingActive
  self.svrStatus = ActivityEnum.ActivitySvrStatus.Unknown
  self.completeTimeStamp = 0
  self.shieldingStatus = false
  self.svrDataInitFlag = false
  self.unlockAdvance = false
  self.loginAccelerateDays = 0
  self.bPopupPlayed = nil
  self.callbacksOnExpired = {}
  if _conf and _conf.recommend_task_id and #_conf.recommend_task_id > 0 then
    self.recommendTaskQueryHandler = TaskQueryHandler(_conf.recommend_task_id)
  end
  self.weakRef = _G.MakeWeakTable({viewPanel = nil}, "v")
  self.leftTimeAttrGroup = _G.MakeWeakTable({}, "k")
  self.activityDescBtnGroup = _G.MakeWeakTable({}, "k")
  self.activityDescDialogCloseCmd = nil
  self.umgName = nil
  self:OnConstruct(_conf, ...)
end

function ActivityObjectBase:OnConstruct(_conf, ...)
end

function ActivityObjectBase:SetEventDispatcher(_eventDispatcher)
  self.eventDispatcher = _eventDispatcher
end

function ActivityObjectBase:__Dctor()
  self:DetachView()
  self:OnDestruct()
end

function ActivityObjectBase:OnDestruct()
end

function ActivityObjectBase:GetActivityId()
  return self.activityConf.id
end

function ActivityObjectBase:GetActivityType()
  return self.activityConf.activity_type
end

function ActivityObjectBase:GetPartIds()
  return self.activityConf.base_id or {}
end

function ActivityObjectBase:GetSinglePartId()
  return self.activityConf.base_id[1]
end

function ActivityObjectBase:GetActivityMainTabId()
  return self.activityConf.maintab_id
end

function ActivityObjectBase:GetActivityName()
  return self.activityConf.activity_name
end

function ActivityObjectBase:GetActivityPromptText()
  return self.activityConf.prompt_text
end

function ActivityObjectBase:GetActivityBanText()
  return self.activityConf.ban_text
end

function ActivityObjectBase:GetActivityDesc()
  return self.activityConf.activity_txt
end

function ActivityObjectBase:GetActivitySpecialDesc()
  local id = self.activityConf.activity_special_txt
  if 0 ~= id then
    return _G.DataConfigManager:GetActivitySpecialTxtConf(id, true)
  end
end

function ActivityObjectBase:GetWorldLevelRequired()
  return self.activityConf.world_level_required
end

function ActivityObjectBase:GetRecommendTaskQueryHandler()
  return self.recommendTaskQueryHandler
end

function ActivityObjectBase:GetRecommendTaskUnfinishedTips()
  return self.activityConf.unfinished_tips
end

function ActivityObjectBase:IsUnlockAdvance()
  return self.unlockAdvance
end

function ActivityObjectBase:GetLoginAccelerateDays()
  return self.loginAccelerateDays
end

function ActivityObjectBase:GetPopupPlayed()
  return self.bPopupPlayed
end

function ActivityObjectBase:GetActivityIcon()
  return self.activityConf.icon_select, self.activityConf.icon
end

function ActivityObjectBase:GetUmgPath()
  return self.activityConf.umg_path
end

function ActivityObjectBase:GetUmgName()
  local umgName = self.umgName
  if not string.IsNilOrEmpty(umgName) then
    return umgName
  end
  local umgPath = self:GetUmgPath()
  if not string.IsNilOrEmpty(umgPath) then
    local parts = {}
    for part in string.gmatch(umgPath, "[^/.]+") do
      table.insert(parts, part)
    end
    if #parts > 1 then
      umgName = parts[#parts - 1]
    end
  end
  if string.IsNilOrEmpty(umgName) then
    umgName = "Activity_" .. tostring(self:GetActivityId())
  end
  self.umgName = umgName
  return umgName
end

function ActivityObjectBase:GetUmgImagePath()
  local imagePath = self.activityConf.image_path
  if not string.IsNilOrEmpty(imagePath) and string.find(imagePath, "|") then
    local paths = string.split(imagePath, "|")
    if paths and #paths >= 2 then
      return _G.DataModelMgr.PlayerDataModel:IsMale() and paths[1] or paths[2]
    end
  end
  return imagePath
end

function ActivityObjectBase:GetActivityBgm()
  return self.activityConf.bgm
end

function ActivityObjectBase:GetTitleIcon()
  return self.activityConf.title_icon
end

function ActivityObjectBase:GetTitleIconText()
  return self.activityConf.title_icon_text
end

function ActivityObjectBase:GetOpenAnimationName()
  return self.activityConf.ae_start
end

function ActivityObjectBase:GetLoopAnimationName()
  return self.activityConf.ae_loop
end

function ActivityObjectBase:GetCloseAnimationName()
  return self.activityConf.ae_end
end

function ActivityObjectBase:GetActivityTypeParam()
  return self.activityConf.type_param
end

function ActivityObjectBase:GetActivityBelongSystem()
  return self.activityConf.belong_system
end

function ActivityObjectBase:GetActivityCompositedKey()
  local compositedKey = self.activityConf.tab_id
  if 0 ~= compositedKey then
    return compositedKey
  end
end

function ActivityObjectBase:GetActivityTimeLeft()
  local endTimestamp = self:GetActivityEndTime() or 0
  if 0 == endTimestamp then
    return math.maxinteger
  end
  if self:IsActivityInactive() then
    return 0
  end
  local serverTimestamp = ActivityUtils.GetSvrTimestamp()
  return math.max(endTimestamp - serverTimestamp, 0)
end

function ActivityObjectBase:SetActivityCompleted(timeStamp)
  self:SetActivityStatus(ActivityEnum.ActivityStatus.Complete)
  self.completeTimeStamp = timeStamp or ActivityUtils.GetSvrTimestamp()
end

function ActivityObjectBase:GetActivityCompletedTimeStamp()
  return self.completeTimeStamp
end

function ActivityObjectBase:IsActivityInactive()
  return self.status == ActivityEnum.ActivityStatus.Expired
end

function ActivityObjectBase:IsActivityUnlock()
  return self.status >= ActivityEnum.ActivityStatus.Available
end

function ActivityObjectBase:PerformActivityInteraction(_interactionType, ...)
  if self.status == ActivityEnum.ActivityStatus.WaitingActive or self.status == ActivityEnum.ActivityStatus.Active then
    return false
  end
  local handled = false
  local inactive = self:IsActivityInactive()
  
  local function JoinActivityImpl(...)
    if not inactive then
      local joinStatus = self:OnTryJoinActivity(...)
      if joinStatus == ActivityEnum.ActivityJoinStatus.Available then
        handled = true
      elseif joinStatus == ActivityEnum.ActivityJoinStatus.Expired then
        inactive = true
      end
    end
  end
  
  local function GetRewardImpl(...)
    if not inactive then
      local rewardStatus = self:OnTryGetReward(...)
      if rewardStatus == ActivityEnum.RewardStatus.Available then
        handled = true
      end
      return rewardStatus
    end
    return ActivityEnum.RewardStatus.UnAvailable
  end
  
  if _interactionType == ActivityEnum.ActivityInteractionType.Join then
    JoinActivityImpl(...)
  elseif _interactionType == ActivityEnum.ActivityInteractionType.GetReward then
    GetRewardImpl(...)
  else
    local rewardStatus = GetRewardImpl(...)
    if not handled and rewardStatus == ActivityEnum.RewardStatus.UnAvailable then
      JoinActivityImpl(...)
    end
  end
  if inactive and not handled then
    handled = true
    ActivityUtils.ShowActivityExpiredTips()
  end
  return handled
end

function ActivityObjectBase:ReqGetPlayerActivityData(callback)
  if self:GetSvrStatus() ~= ActivityEnum.ActivitySvrStatus.Available or self:GetShieldingStatus() then
    return
  end
  self.callbackOnRspPlayerActivityData = callback
  local req = _G.ProtoMessage:newZoneGetPlayerActivityDataReq()
  req.activity_id = self:GetActivityId()
  Log.Info("ReqGetPlayerActivityData: ", req.activity_id)
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_REQ, req)
end

function ActivityObjectBase:ReqGetPlayerActivityHistoryData(_activityType)
  local req = _G.ProtoMessage:newZoneGetPlayerActivityHistoryDataReq()
  req.activity_type = _activityType or self:GetActivityType()
  ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_HISTORY_DATA_REQ, req, self, self.OnZoneGetPlayerActivityHistoryDataRsp)
end

function ActivityObjectBase:ReqActivityUnlockAdvance()
  if self:IsUnlockAdvance() then
    return
  end
  local req = _G.ProtoMessage:newZoneActivityUnlockAdvanceReq()
  req.activity_id = self:GetActivityId()
  ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_UNLOCK_ADVANCE_REQ, req, self, self.OnZoneActivityUnlockAdvanceRsp)
end

function ActivityObjectBase:GetActivityHistoryData()
  return GetActivityObjectClassData(self, "_historyData")
end

function ActivityObjectBase:GetTabRedPointExtraKeyList()
  local extraKeyList = {}
  table.insert(extraKeyList, {
    self:GetActivityId()
  })
  local _customExtraKeyList = self:GetTabRedPointCustomExtraKeyList()
  if _customExtraKeyList then
    for _, _extraKey in ipairs(_customExtraKeyList) do
      table.insert(extraKeyList, _extraKey)
    end
  end
  return extraKeyList
end

function ActivityObjectBase:AddActivityExpiredCallback(identifier, caller, callback, ...)
  if not identifier or not self.callbacksOnExpired then
    return
  end
  self.callbacksOnExpired[identifier] = _G.MakeWeakFunctor(caller, callback, ...)
end

function ActivityObjectBase:IsActivityOpen()
  return true
end

function ActivityObjectBase:IsActivityClose()
  return false
end

function ActivityObjectBase:GetActivityStartTime()
  if string.IsNilOrEmpty(self.activityConf.appear_time) then
    return 0
  end
  return ActivityUtils.ToTimestamp(self.activityConf.appear_time)
end

function ActivityObjectBase:GetActivityEndTime()
  if string.IsNilOrEmpty(self.activityConf.disappear_time) then
    return 0
  end
  return ActivityUtils.ToTimestamp(self.activityConf.disappear_time)
end

function ActivityObjectBase:OnRefreshActivityData(_activateParameter)
end

function ActivityObjectBase:OnActivitySvrStatusChanged(available)
end

function ActivityObjectBase:SyncActivityDataOnAvailable()
  if self.activityConf.success_if_disappear then
    self:ReqGetPlayerActivityData()
  end
end

function ActivityObjectBase:OnSvrUpdateActivityData(_cmdId, _updateData, _initUpdate)
end

function ActivityObjectBase:OnSvrUpdateActivityHistoryData(_activityData)
end

function ActivityObjectBase:OnAttachView(_view)
end

function ActivityObjectBase:OnDetachView()
end

function ActivityObjectBase:LoadViewClass(caller, callbackLoaded)
  return false
end

function ActivityObjectBase:OnTryGetReward(...)
  return ActivityEnum.RewardStatus.UnAvailable
end

function ActivityObjectBase:OnTryJoinActivity(...)
  return ActivityEnum.ActivityJoinStatus.Unsatisfied
end

function ActivityObjectBase:GetTabRedPointCustomExtraKeyList()
end

function ActivityObjectBase:GetActivityLoginDays()
  local svrTime = ActivityUtils.GetSvrTimestamp()
  local beginTime = self.activity_open_time or self:GetActivityStartTime()
  if svrTime < beginTime then
    return 0
  end
  local timeStr = _G.DataConfigManager:GetGlobalConfig("activity_daily_refresh_time").str
  local hour, minute, second = string.match(timeStr, "^(%d%d):(%d%d):(%d%d)$")
  hour = tonumber(hour)
  minute = tonumber(minute)
  second = tonumber(second)
  local dateTable = os.date("*t", beginTime)
  local ExtraDay = 0
  if hour > dateTable.hour or dateTable.hour == hour and minute > dateTable.min or dateTable.hour == hour and dateTable.min == minute and second > dateTable.sec then
    ExtraDay = 1
  end
  dateTable.hour = hour
  dateTable.min = minute
  dateTable.sec = second
  beginTime = os.time(dateTable)
  local acivityDays = math.ceil((svrTime - beginTime) / 86400) + ExtraDay
  local activityLoginDays = 0
  local loginHistory = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityLoginDays)
  if loginHistory then
    for _, _value in ipairs(loginHistory) do
      if acivityDays <= 0 then
        break
      end
      for i = 0, 31 do
        if acivityDays <= 0 then
          break
        end
        local tempValue = _value & 1 << i
        if tempValue > 0 then
          activityLoginDays = activityLoginDays + 1
        end
        acivityDays = acivityDays - 1
      end
    end
  end
  return activityLoginDays
end

function ActivityObjectBase:IsInProgress()
  return self:GetSvrStatus() == ActivityEnum.ActivitySvrStatus.Available
end

function ActivityObjectBase:OnReconnectFinish()
  return false
end

function ActivityObjectBase:BindActivityTimeLeft(_textCtrl)
  if _textCtrl then
    local _leftTimeAttr = self.leftTimeAttrGroup[_textCtrl]
    if nil == _leftTimeAttr then
      _leftTimeAttr = AttrBindingUtils.CreateTextBinding()
      self.leftTimeAttrGroup[_textCtrl] = _leftTimeAttr
    end
    _leftTimeAttr:Bind(_textCtrl, ActivityUtils.GetTimeFormatStr(self:GetActivityTimeLeft()))
  end
end

function ActivityObjectBase:UnBindActivityTimeLeft(_textCtrl)
  if _textCtrl then
    local _leftTimeAttr = self.leftTimeAttrGroup[_textCtrl]
    if _leftTimeAttr then
      _leftTimeAttr:UnBind()
      self.leftTimeAttrGroup[_textCtrl] = nil
    end
  end
end

function ActivityObjectBase:BindActivityDesc(_btnCtrl, _uiView)
  if _btnCtrl then
    local _activityDescBtn = self.activityDescBtnGroup[_btnCtrl]
    if nil == _activityDescBtn then
      _activityDescBtn = AttrBindingUtils.CreateBtnBinding(self.OnBtnShowActivityDesc, self)
      self.activityDescBtnGroup[_btnCtrl] = _activityDescBtn
    end
    _activityDescBtn:AttachUIView(_uiView)
    _activityDescBtn:Bind(_btnCtrl)
  end
end

function ActivityObjectBase:UnBindActivityDesc(_btnCtrl)
  if _btnCtrl then
    local _activityDescBtn = self.activityDescBtnGroup[_btnCtrl]
    if _activityDescBtn then
      _activityDescBtn:UnBind()
      self.activityDescBtnGroup[_btnCtrl] = nil
    end
  end
end

function ActivityObjectBase:OnBtnShowActivityDesc()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "ActivityObjectBase:OnBtnShowActivityDesc")
  local activitySpecialDesc = self:GetActivitySpecialDesc()
  if activitySpecialDesc then
    local activityCommonData = {}
    activityCommonData.titleText = _G.LuaText.activity_tip_headline
    activityCommonData.entries = {}
    for _, v in ipairs(activitySpecialDesc.explain_group) do
      local entry = {}
      entry.desc = v.txt
      entry.imagPath = v.image_path
      table.insert(activityCommonData.entries, entry)
    end
    _G.NRCModeManager:DoCmd(_G.CommonPopUpModuleCmd.OpenActivityCommonPanel, activityCommonData)
    return
  end
  local activityDesc = self:GetActivityDesc()
  if string.IsNilOrEmpty(activityDesc) then
    Log.ErrorFormat("\230\180\187\229\138\168id=%d,\230\156\170\233\133\141\231\189\174\232\167\132\229\136\153\232\175\180\230\152\142!", self:GetActivityId())
    return
  end
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  Context:SetTitle(_G.LuaText.activity_tip_headline):SetContent(activityDesc):SetContentTextJustify(UE4.ETextJustify.Left):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true):SetCallback(self, self.OnActivityDescDialogClosed)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
  self.activityDescDialogCloseCmd = _G.TipsModuleCmd.Dialog_CloseLongDialog
end

function ActivityObjectBase:OnActivityDescDialogClosed()
  self.activityDescDialogCloseCmd = nil
end

function ActivityObjectBase:CompareTo(_otherActivityData)
  local a = self.activityConf
  local b = _otherActivityData.activityConf
  if a.priority ~= b.priority then
    return a.priority > b.priority
  end
  local timeStamp1 = ActivityUtils.ToTimestamp(a.appear_time)
  local timeStamp2 = ActivityUtils.ToTimestamp(b.appear_time)
  return timeStamp1 > timeStamp2
end

function ActivityObjectBase:GetAttachView()
  return self.weakRef.viewPanel
end

function ActivityObjectBase:AttachView(_view)
  if not _view then
    return
  end
  self.weakRef.viewPanel = _view
  self:TickActivityLeftTime(true)
  self:OnAttachView(_view)
end

function ActivityObjectBase:DetachView()
  self.weakRef.viewPanel = nil
  for _, _leftTimeAttr in pairs(self.leftTimeAttrGroup) do
    _leftTimeAttr:UnBind()
  end
  for _, _activityDescBtn in pairs(self.activityDescBtnGroup) do
    _activityDescBtn:UnBind()
  end
  self:TickActivityLeftTime(false)
  self:OnDetachView()
  if not string.IsNilOrEmpty(self.activityDescDialogCloseCmd) then
    _G.NRCModuleManager:DoCmd(self.activityDescDialogCloseCmd)
  end
end

function ActivityObjectBase:EraseNewActivityRedPoint()
  local newRedKey
  if self:GetActivityBelongSystem() == _G.Enum.BelongSystem.BS_RECALL_ACTIVITY then
    newRedKey = 488
  else
    newRedKey = ActivityEnum.RedPointKey.NewActivity
  end
  _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, newRedKey, tostring(self:GetActivityId()), true)
end

function ActivityObjectBase:GetActivityShowStatus()
  if self.shieldingStatus then
    return ActivityEnum.ActivityShowStatus.Disable_Shielding
  end
  if self.activityConf then
    if self.activityConf.if_hide then
      return ActivityEnum.ActivityShowStatus.Disable_ConfigHide
    end
    if self.activityConf.belong_system == Enum.BelongSystem.BS_SEASON then
      return ActivityEnum.ActivityShowStatus.Disable_BelongSeason
    end
  end
  if self.status == ActivityEnum.ActivityStatus.Active or self.status == ActivityEnum.ActivityStatus.Available then
    return ActivityEnum.ActivityShowStatus.Enable
  elseif self.status == ActivityEnum.ActivityStatus.Complete then
    local shouldDisappear = false
    if self.activityConf.success_if_disappear then
      local competeTimestamp = self.completeTimeStamp
      if 0 ~= competeTimestamp then
        local nowTimestamp = ActivityUtils.GetSvrTimestamp()
        local timeSpan = nowTimestamp - competeTimestamp
        if timeSpan >= 86400 then
          shouldDisappear = true
        elseif timeSpan > 0 then
          local nowTimeDetail = ActivityUtils.ToTimeDetailData(nowTimestamp)
          if nowTimeDetail.hour >= 4 then
            local competeTimeDetail = ActivityUtils.ToTimeDetailData(competeTimestamp)
            if nowTimeDetail.day == competeTimeDetail.day and competeTimeDetail.hour < 4 then
              shouldDisappear = true
            elseif nowTimeDetail.day == competeTimeDetail.day + 1 and competeTimeDetail.hour >= 4 then
              shouldDisappear = true
            end
          end
        elseif timeSpan < 0 then
        end
      end
    end
    return shouldDisappear and ActivityEnum.ActivityShowStatus.Disable_CompleteDisappear or ActivityEnum.ActivityShowStatus.Enable
  else
    if self.svrStatus == ActivityEnum.ActivitySvrStatus.Available then
      return ActivityEnum.ActivityShowStatus.Enable
    end
    if self.status == ActivityEnum.ActivityStatus.Expired then
      return ActivityEnum.ActivityShowStatus.Disable_Expired
    end
  end
  return ActivityEnum.ActivityShowStatus.Disable_NotActive
end

function ActivityObjectBase:SetSvrStatus(_status)
  if _status == ActivityEnum.ActivitySvrStatus.Available then
    local myActivityId = self:GetActivityId()
    if self.activityConf.popup_path then
      _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.TryShowActivityCommonOpenTips, myActivityId)
      self.bTryShowTipsAfterDataUpdate = true
    end
  end
  if self.svrStatus == ActivityEnum.ActivitySvrStatus.Available and _status == ActivityEnum.ActivitySvrStatus.UnAvailable then
    self:SetActivityStatus(ActivityEnum.ActivityStatus.Expired)
    for _, _leftTimeAttr in pairs(self.leftTimeAttrGroup) do
      _leftTimeAttr:Set(ActivityUtils.GetTimeFormatStr(0))
    end
  end
  if self.svrStatus ~= _status then
    self.svrStatus = _status
    if _status == ActivityEnum.ActivitySvrStatus.Available then
      self:SyncActivityDataOnAvailable()
    end
    self:OnActivitySvrStatusChanged(_status == ActivityEnum.ActivitySvrStatus.Available)
    self:SendEvent(ActivityModuleEvent.ActivitySvrStateChanged, self)
  end
end

function ActivityObjectBase:GetSvrStatus()
  return self.svrStatus
end

function ActivityObjectBase:SetShieldingStatus(_shielding)
  self.shieldingStatus = _shielding
end

function ActivityObjectBase:GetShieldingStatus()
  return self.shieldingStatus
end

function ActivityObjectBase:RefreshActivityStatus(_activateParameter)
  if self.status == ActivityEnum.ActivityStatus.Expired then
    return
  end
  self:OnRefreshActivityData(_activateParameter)
  if self:IsActivityExpired(_activateParameter.serverTime) then
    self:SetActivityStatus(ActivityEnum.ActivityStatus.Expired)
    return
  end
  if self.status == ActivityEnum.ActivityStatus.WaitingActive then
    if self.svrStatus == ActivityEnum.ActivitySvrStatus.Available then
      self:SetActivityStatus(ActivityEnum.ActivityStatus.Available)
    elseif self.activityConf.if_appear then
      self:SetActivityStatus(ActivityEnum.ActivityStatus.Active)
    end
  elseif self.status == ActivityEnum.ActivityStatus.Active then
    if self.svrStatus == ActivityEnum.ActivitySvrStatus.Available then
      self:SetActivityStatus(ActivityEnum.ActivityStatus.Available)
    end
  elseif self.status == ActivityEnum.ActivityStatus.Available and self.svrStatus == ActivityEnum.ActivitySvrStatus.UnAvailable then
    self:SetActivityStatus(ActivityEnum.ActivityStatus.WaitingActive)
  end
end

function ActivityObjectBase:TickActivityLeftTime(_enable, _leftSeconds)
  if self.UpdateActivityLeftTimeId then
    _G.DelayManager:CancelDelayById(self.UpdateActivityLeftTimeId)
    self.UpdateActivityLeftTimeId = nil
  end
  if _enable then
    local leftSeconds = _leftSeconds or self:GetActivityTimeLeft()
    if leftSeconds ~= math.maxinteger then
      self.UpdateActivityLeftTimeId = _G.DelayManager:DelaySeconds(math.min(leftSeconds, 60), self.UpdateActivityLeftTimeOnce, self)
    end
  end
end

function ActivityObjectBase:SvrUpdateActivityData(_cmdId, _updateData)
  if _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    local _activityData = _updateData
    self.unlockAdvance = _activityData and _activityData.activity_unlock_advance or false
    self.loginAccelerateDays = _activityData and _activityData.login_accelerate_days or 0
    self.bPopupPlayed = _activityData and _activityData.popup_played or false
  elseif _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_POPUP_PLAYED_RSP then
    self.bPopupPlayed = true
  end
  if self.svrDataInitFlag then
    self:OnSvrUpdateActivityData(_cmdId, _updateData, false)
  else
    self:OnSvrUpdateActivityData(_cmdId, _updateData, true)
  end
  self.svrDataInitFlag = true
  local callback = self.callbackOnRspPlayerActivityData
  if callback and _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    callback()
    self.callbackOnRspPlayerActivityData = nil
  end
  if self.svrStatus == ActivityEnum.ActivitySvrStatus.Available and self.bTryShowTipsAfterDataUpdate and self.activityConf and self.activityConf.popup_path then
    self.bTryShowTipsAfterDataUpdate = nil
    local myActivityId = self:GetActivityId()
    _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.TryShowActivityCommonOpenTips, myActivityId)
  end
end

function ActivityObjectBase:OnZoneGetPlayerActivityHistoryDataRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  SetActivityObjectClassData(self, "_historyData", _protoData.activity_data)
  self:OnSvrUpdateActivityHistoryData(_protoData.activity_data)
end

function ActivityObjectBase:OnZoneActivityUnlockAdvanceRsp(_protoData, _req)
  if not _protoData or 0 ~= _protoData.ret_info.ret_code then
    return
  end
  if _req and _req.activity_id == self:GetActivityId() then
    self.unlockAdvance = true
  end
end

function ActivityObjectBase:SetActivityStatus(_status)
  if self.status ~= _status then
    self.status = _status
    if _status == ActivityEnum.ActivityStatus.Expired and self.callbacksOnExpired then
      for _, _callback in pairs(self.callbacksOnExpired) do
        _callback()
      end
      self.callbacksOnExpired = {}
    end
  end
end

function ActivityObjectBase:IsActivityStart(_serverTime)
  if not self:IsActivityOpen() then
    return false
  end
  local startTimestamp = self:GetActivityStartTime()
  if 0 == startTimestamp then
    return true
  end
  return _serverTime >= startTimestamp
end

function ActivityObjectBase:IsActivityExpired(_serverTime)
  if self:IsActivityClose() then
    return true
  end
  local endTimestamp = self:GetActivityEndTime() or 0
  if 0 == endTimestamp then
    return false
  end
  return _serverTime >= endTimestamp
end

function ActivityObjectBase:UpdateActivityLeftTimeOnce()
  self.UpdateActivityLeftTimeId = nil
  local leftSeconds = self:GetActivityTimeLeft()
  if leftSeconds > 0 then
    self:SendEvent(ActivityModuleEvent.ActivityLeftTimeChange, self, leftSeconds)
    self:TickActivityLeftTime(true, leftSeconds)
  else
    self:SetActivityStatus(ActivityEnum.ActivityStatus.Expired)
  end
  for _, _leftTimeAttr in pairs(self.leftTimeAttrGroup) do
    _leftTimeAttr:Set(ActivityUtils.GetTimeFormatStr(leftSeconds))
  end
end

function ActivityObjectBase:AddEventListener(listener, eventType, handler)
  if self.eventDispatcher then
    self.eventDispatcher:AddEventListener(listener, eventType, handler)
  end
end

function ActivityObjectBase:RemoveEventListener(listener, eventType, handler)
  if self.eventDispatcher then
    self.eventDispatcher:RemoveEventListener(listener, eventType, handler)
  end
end

function ActivityObjectBase:SendEvent(eventType, ...)
  if self.eventDispatcher then
    self.eventDispatcher:SendEvent(eventType, ...)
  end
end

function ActivityObjectBase:SendTLogActivityInteraction(InteractionType)
  local BaseIds = self:GetPartIds()
  for _, BaseId in ipairs(BaseIds) do
    ActivityUtils.SendTLogActivityInteraction(self:GetActivityId(), BaseId, InteractionType, self:GetActivityMainTabId(), 1)
  end
end

return ActivityObjectBase
