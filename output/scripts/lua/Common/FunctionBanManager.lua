local FunctionBanModuleEvent = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleEvent")
local FunctionBanEnum = require("NewRoco.Modules.System.FunctionBan.FunctionBanEnum")
local BlockingFuncType = {System = 1, Activity = 2}
local FunctionBanManager = Singleton:Extend("FunctionBanManager")
local EventDispatcher = require("Common.EventDispatcher")

function FunctionBanManager:Ctor()
  Singleton.Ctor(self, self.name)
  self.ReportEvtToServer = true
  self.eventDispatcher = NRCClass()
  EventDispatcher():Attach(self.eventDispatcher)
  self:Init()
end

function FunctionBanManager:Init()
  Log.Debug(" FunctionBanManager:Init")
  self.functionStateDic = {}
  self.playerConditionDic = {}
  self.conditionCounterDic = {}
  self.condTypeToCliEventMap = {}
  self:InitToServerEvtMap()
  self:InitFunctionState()
  self:InitFunctionBanTypeUIBanIndices()
  self:InitFuncBlockingConf()
  self:InitializeFunctionBanNameMap()
end

function FunctionBanManager:InitToServerEvtMap()
  self.condTypeToCliEventMap[Enum.PlayerConditionType.PCT_FULLSCREEN_UI] = Enum.ClientEvent.CE_UI_FULL_SCENE
  self.condTypeToCliEventMap[Enum.PlayerConditionType.PCT_UI] = Enum.ClientEvent.CE_UI_NOT_FULL_SCENE
  self.condTypeToCliEventMap[Enum.PlayerConditionType.PCT_CG] = Enum.ClientEvent.CE_CG
  self.condTypeToCliEventMap[Enum.PlayerConditionType.PCT_TAKE_PHOTO_HANDHELD] = Enum.ClientEvent.CE_TAKE_PHOTO_HANDHELD
  self.condTypeToCliEventMap[Enum.PlayerConditionType.PCT_TAKE_PHOTO_TRIPOD_CAMERA] = Enum.ClientEvent.CE_TAKE_PHOTO_TRIPOD_CAMERA
  self.condTypeToCliEventMap[Enum.PlayerConditionType.PCT_TAKE_PHOTO_TRIPOD_WORLD] = Enum.ClientEvent.CE_TAKE_PHOTO_TRIPOD_WORLD
  self.condTypeToCliEventMap[Enum.PlayerConditionType.PCT_TAKE_PHOTO_MYSELF] = Enum.ClientEvent.CE_TAKE_PHOTO_MYSELF
  self.condTypeToCliEventMap[Enum.PlayerConditionType.PCT_OPEN_PLAYER_RELATIONSHIP_TREE] = Enum.ClientEvent.CE_OPEN_PLAYER_RELATIONSHIP_TREE
end

function FunctionBanManager:InitFunctionState()
  local functionType = Enum.PlayerFunctionBanType
  for _, v in pairs(functionType) do
    if v ~= Enum.PlayerFunctionBanType.PFBT_BEGIN and v ~= Enum.PlayerFunctionBanType.PFBT_END then
      self.functionStateDic[v] = self:CreateFunctionState()
    end
  end
end

function FunctionBanManager:ClearAll()
  self:Init()
end

function FunctionBanManager:CreateFunctionState()
  return {banCount = 0, lastUnbanTime = -1}
end

function FunctionBanManager:InitFunctionBanTypeUIBanIndices()
  local UI_BAN_CONF = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.UI_BAN_CONF):GetAllDatas()
  local Indices = {}
  for _, BanConf in pairs(UI_BAN_CONF) do
    if Indices[BanConf.function_ban_id] then
      self:LogError("duplicate function_ban_id in UI_BAN_CONF", Indices[BanConf.function_ban_id].ui_ban_id, BanConf.ui_ban_id)
    else
      Indices[BanConf.function_ban_id] = BanConf
    end
  end
  self.functionEntranceUIBanVisibleRefNums = {}
  self.conditionTypeToUIBanConf = Indices
end

function FunctionBanManager:OnUIBanFunctionPreChanged(ConditionType)
  local BanConf = self.conditionTypeToUIBanConf[ConditionType]
  if not BanConf then
    return
  end
  local FunctionEntranceVisible = {}
  for _, FunctionEntrance in ipairs(BanConf.ui_ban_icon) do
    local bHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, FunctionEntrance)
    FunctionEntranceVisible[FunctionEntrance] = bHide
  end
  return FunctionEntranceVisible
end

function FunctionBanManager:OnUIBanFunctionChanged(Banned, ConditionType, FunctionEntranceVisible)
  local BanConf = self.conditionTypeToUIBanConf[ConditionType]
  if not BanConf then
    return
  end
  Log.Debug("FunctionBan join condition", Banned, ConditionType)
  local ModifyCount = Banned and 1 or -1
  local ChangedFunc = {}
  for _, FunctionEntrance in ipairs(BanConf.ui_ban_icon) do
    local ElapsedCount = self.functionEntranceUIBanVisibleRefNums[FunctionEntrance] or 0
    local TargetCount = ElapsedCount + ModifyCount
    self.functionEntranceUIBanVisibleRefNums[FunctionEntrance] = TargetCount
    Log.Debug("FunctionBan FunctionEntrance", FunctionEntrance, ElapsedCount, TargetCount, FunctionEntranceVisible[FunctionEntrance])
    if 0 == ElapsedCount * TargetCount then
      table.insert(ChangedFunc, FunctionEntrance)
    end
  end
  for i, Func in ipairs(ChangedFunc) do
    local bHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckIfUIFuncVisibilityChange, Func, FunctionEntranceVisible[Func])
    if bHide ~= FunctionEntranceVisible[Func] then
      Log.Debug("FunctionBan FuncEntrance visible changed by:", Banned, ConditionType, "hide:", Func, bHide)
    end
  end
end

function FunctionBanManager:OnCheckUIBanForbidden(FunctionEntrance)
  return (FunctionEntrance and self.functionEntranceUIBanVisibleRefNums[FunctionEntrance] or 0) > 0
end

local function ExtractVersionStrNumbers(inputVerString)
  local numbers = table.new(4, 0)
  if inputVerString then
    for num in string.gmatch(inputVerString, "([^%.]+)") do
      table.insert(numbers, tonumber(num))
    end
  end
  return numbers
end

local LoginPlatLimitMask = {
  [Enum.PlatType.PT_IOS] = 1,
  [Enum.PlatType.PT_ANDROID] = 2,
  [Enum.PlatType.PT_PC] = 4,
  [Enum.PlatType.PT_EDITOR] = 8,
  [Enum.PlatType.PT_HARMONY_OS] = 4096,
  [Enum.PlatType.PT_HARMONY_PC] = 8192
}

function FunctionBanManager:InitFuncBlockingConf()
  if self.funcBlockingConfInitFlag then
    return
  end
  self.funcBlockingConfInitFlag = true
  self.gmSkipFuncBlocking = false
  self.SystemFuncBlockingConf = {}
  self.ActivityBlockingConf = {}
  self.FuncBlockingChannelConf = {}
  self.isAuditServer = false
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_FUNC_BLOCKING_CONFS_CHANGE_NOTIFY, self.OnZoneFuncBlockingConfsChangeNotify)
end

function FunctionBanManager:OnZoneFuncBlockingConfsChangeNotify(_protoData)
  if not _protoData or not _protoData.func_blocking_confs_list then
    Log.Error("OnZoneFuncBlockingConfsChangeNotify _protoData is not valid")
    return
  end
  local newSystemFuncBlockingConf = {}
  local newActivityBlockingConf = {}
  local newFuncBlockingChannelConf = {}
  for _, conf in ipairs(_protoData.func_blocking_confs_list) do
    if conf.func_confs then
      local funcBlockingConf, oldFuncBlockingConf
      if conf.func_type == BlockingFuncType.System then
        funcBlockingConf = newSystemFuncBlockingConf
        oldFuncBlockingConf = self.SystemFuncBlockingConf
      elseif conf.func_type == BlockingFuncType.Activity then
        funcBlockingConf = newActivityBlockingConf
        oldFuncBlockingConf = self.ActivityBlockingConf
      else
        Log.ErrorFormat("OnZoneFuncBlockingConfsChangeNotify conf.func_type(%d) is not valid", conf.func_type or 0)
      end
      if funcBlockingConf then
        for _, funcConf in ipairs(conf.func_confs) do
          local oldFuncConf = oldFuncBlockingConf and oldFuncBlockingConf[funcConf.func_id]
          local item = funcConf
          item.funcType = conf.func_type
          item.entranceBlockingType = oldFuncConf and oldFuncConf.entranceBlockingType or FunctionBanEnum.EntranceBlockingType.None
          funcBlockingConf[funcConf.func_id] = item
        end
      end
    end
    if conf.channel_confs then
      for _, channelConf in ipairs(conf.channel_confs) do
        newFuncBlockingChannelConf[channelConf.channel_conf_id] = channelConf
      end
    end
  end
  self.SystemFuncBlockingConf = newSystemFuncBlockingConf
  self.ActivityBlockingConf = newActivityBlockingConf
  self.FuncBlockingChannelConf = newFuncBlockingChannelConf
  self.isAuditServer = _protoData.is_audit
  self:RefreshClientFuncBlockingConf()
end

function FunctionBanManager:GetEntranceBlockingTypeByClientData(clientData, funcItem, uiFunctionId)
  if 1 ~= funcItem.is_open then
    Log.Debug("[SvrBan]", uiFunctionId, "is_open ~= 1")
    return FunctionBanEnum.EntranceBlockingType.Lock
  end
  if 1 ~= funcItem.is_audit and self.isAuditServer then
    Log.Debug("[SvrBan]", uiFunctionId, "is_audit ~= 1")
    return FunctionBanEnum.EntranceBlockingType.Hide
  end
  if funcItem.login_plat_limit then
    local limitMask = 0
    for _, platformMask in ipairs(funcItem.login_plat_limit) do
      limitMask = limitMask | platformMask
    end
    if 0 ~= limitMask then
      local loginPlatMask = LoginPlatLimitMask[clientData.loginPlat] or 0
      if 0 ~= limitMask & loginPlatMask then
        Log.Debug("[SvrBan]", uiFunctionId, clientData.loginPlat, "in login plat limit!")
        return FunctionBanEnum.EntranceBlockingType.Hide
      end
    end
  end
  if funcItem.channel_conf_id then
    local funcBlockingChannelConf = self.FuncBlockingChannelConf
    local channelConf = funcBlockingChannelConf and funcBlockingChannelConf[funcItem.channel_conf_id]
    if channelConf then
      if channelConf.display_platform then
        for _, platform in ipairs(channelConf.display_platform) do
          if -1 == platform then
            Log.Debug("[SvrBan]", uiFunctionId, "display_platform == -1, channel", funcItem.channel_conf_id)
            return FunctionBanEnum.EntranceBlockingType.Hide
          elseif 0 ~= platform and clientData.loginChannel ~= platform then
            Log.Debug("[SvrBan]", uiFunctionId, clientData.loginChannel, "not in display_platform, channel", funcItem.channel_conf_id)
            return FunctionBanEnum.EntranceBlockingType.Hide
          end
        end
      end
      if channelConf.pkg_channel_hidden_list then
        for _, channel in ipairs(channelConf.pkg_channel_hidden_list) do
          if channel == clientData.channelId then
            Log.Debug("[SvrBan]", uiFunctionId, clientData.channelId, "in hidden channel list")
            return FunctionBanEnum.EntranceBlockingType.Hide
          end
        end
      end
      if channelConf.pkg_channel_show_list and #channelConf.pkg_channel_show_list > 0 then
        local inShowList = false
        for _, channel in ipairs(channelConf.pkg_channel_show_list) do
          if channel == clientData.channelId then
            inShowList = true
            break
          end
        end
        if not inShowList then
          Log.Debug("[SvrBan]", uiFunctionId, clientData.channelId, "not in show channel List")
          return FunctionBanEnum.EntranceBlockingType.Hide
        end
      end
    end
  end
  if 1 ~= funcItem.version_rule and not string.IsNilOrEmpty(clientData.version) then
    local configVersion
    if clientData.loginPlat == Enum.PlatType.PT_IOS then
      configVersion = funcItem.open_client_version_ios
    elseif clientData.loginPlat == Enum.PlatType.PT_ANDROID then
      configVersion = funcItem.open_client_version_android
    elseif clientData.loginPlat == Enum.PlatType.PT_PC then
      configVersion = funcItem.open_client_version_pc
    elseif clientData.loginPlat == Enum.PlatType.PT_HARMONY_OS then
      configVersion = funcItem.open_client_version_harmony_os
    elseif clientData.loginPlat == Enum.PlatType.PT_HARMONY_PC then
      configVersion = funcItem.open_client_version_harmony_pc
    end
    if not string.IsNilOrEmpty(configVersion) and clientData.version ~= configVersion then
      local configVersionNumbers = ExtractVersionStrNumbers(configVersion)
      local compareStart = math.min(#configVersionNumbers, #clientData.versionNumbers)
      for i = compareStart, 1, -1 do
        if clientData.versionNumbers[i] < configVersionNumbers[i] then
          Log.Debug("[SvrBan]", uiFunctionId, clientData.version, "is lower than", configVersion)
          return FunctionBanEnum.EntranceBlockingType.NeedNewVersion
        end
      end
    end
  end
  return FunctionBanEnum.EntranceBlockingType.None
end

function FunctionBanManager:OnSystemFuncBlockingTypeChange(funcId, entranceBlockingType)
  _G.NRCEventCenter:DispatchEvent(FunctionBanModuleEvent.OnSystemFuncBlockingTypeChange, funcId, entranceBlockingType)
end

function FunctionBanManager:RefreshClientFuncBlockingConf()
  if self.gmSkipFuncBlocking then
    return
  end
  Log.Debug("[SvrBan] RefreshClientFuncBlockingConf")
  local clientData = {
    isAudit = _G.AppMain:IsAuditVersion(),
    version = _G.AppMain:GetResVersion(),
    versionNumbers = ExtractVersionStrNumbers(_G.AppMain:GetResVersion()),
    channelId = UE.ULoginStatics.GetConfigChannel(),
    loginChannel = nil
  }
  local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  if accountInfo and accountInfo.plat_info then
    clientData.loginChannel = accountInfo.plat_info.cli_login_channel
    clientData.loginPlat = accountInfo.plat_info.plat_id
  end
  
  local function RefreshClientFuncBlockingConfImpl(funcBlockingConf, callback)
    if not funcBlockingConf then
      return
    end
    for uiFunctionId, funcItem in pairs(funcBlockingConf) do
      local preEntranceBlockingType = funcItem.entranceBlockingType
      funcItem.entranceBlockingType = self:GetEntranceBlockingTypeByClientData(clientData, funcItem, uiFunctionId)
      if callback then
        callback(preEntranceBlockingType, funcItem)
      end
    end
  end
  
  do
    local shieldingActivities = {}
    RefreshClientFuncBlockingConfImpl(self.ActivityBlockingConf, function(preEntranceBlockingType, funcItem)
      if funcItem.entranceBlockingType and funcItem.entranceBlockingType ~= FunctionBanEnum.EntranceBlockingType.None then
        table.insert(shieldingActivities, funcItem.func_id)
      end
    end)
    _G.NRCEventCenter:DispatchEvent(FunctionBanModuleEvent.OnShieldingActivitiesChange, shieldingActivities)
  end
  RefreshClientFuncBlockingConfImpl(self.SystemFuncBlockingConf, function(preEntranceBlockingType, funcItem)
    if funcItem.entranceBlockingType ~= preEntranceBlockingType then
      self:OnSystemFuncBlockingTypeChange(funcItem.func_id, funcItem.entranceBlockingType)
    end
  end)
end

function FunctionBanManager:GetFuncBlockingStateBySvrData(uiFunctionId)
  if not self.gmSkipFuncBlocking then
    local systemFuncBlockingConf = self.SystemFuncBlockingConf
    local funcBlockingConf = systemFuncBlockingConf and systemFuncBlockingConf[uiFunctionId]
    if funcBlockingConf then
      return funcBlockingConf.entranceBlockingType
    end
  end
end

function FunctionBanManager:GetSvrShieldingActivities()
  local shieldingActivities = {}
  if not self.gmSkipFuncBlocking then
    local activityBlockingConf = self.ActivityBlockingConf
    if activityBlockingConf then
      for _, funcItem in pairs(activityBlockingConf) do
        if funcItem.entranceBlockingType and funcItem.entranceBlockingType ~= FunctionBanEnum.EntranceBlockingType.None then
          table.insert(shieldingActivities, funcItem.func_id)
        end
      end
    end
  end
  return shieldingActivities
end

function FunctionBanManager:GmSkipFuncBlocking(skip)
  self.gmSkipFuncBlocking = skip
  if skip then
    _G.NRCEventCenter:DispatchEvent(FunctionBanModuleEvent.OnShieldingActivitiesChange, {})
    local systemFuncBlockingConf = self.SystemFuncBlockingConf
    if systemFuncBlockingConf then
      for _, funcItem in pairs(systemFuncBlockingConf) do
        if funcItem.entranceBlockingType and funcItem.entranceBlockingType ~= FunctionBanEnum.EntranceBlockingType.None then
          self:OnSystemFuncBlockingTypeChange(funcItem.func_id, FunctionBanEnum.EntranceBlockingType.None)
        end
      end
    end
  else
    self:RefreshClientFuncBlockingConf()
  end
end

function FunctionBanManager:GetSvrFuncBlockingDebugData()
  local debugData = {}
  local svrConf = {}
  debugData.conf = svrConf
  svrConf.ActivityConf = self.ActivityBlockingConf
  svrConf.SystemConf = self.SystemFuncBlockingConf
  svrConf.ChannelConf = self.FuncBlockingChannelConf
  local functionEntranceMap = {}
  for str, v in pairs(Enum.FunctionEntrance) do
    functionEntranceMap[v] = str
  end
  local blockingData = {}
  debugData.blocking = blockingData
  local activityBlockingConf = self.ActivityBlockingConf
  if activityBlockingConf then
    local activityBlockingData = {}
    blockingData.activity_blocking = activityBlockingData
    for _, funcItem in pairs(activityBlockingConf) do
      if funcItem.entranceBlockingType and funcItem.entranceBlockingType ~= FunctionBanEnum.EntranceBlockingType.None then
        local activityId = funcItem.func_id
        local activityConf = _G.DataConfigManager:GetActivityConf(activityId)
        table.insert(activityBlockingData, string.format("%s(%d)", activityConf and activityConf.activity_name or "", activityId))
      end
    end
  end
  local systemFuncBlockingConf = self.SystemFuncBlockingConf
  if systemFuncBlockingConf then
    local systemBlockingData = {}
    blockingData.system_blocking = systemBlockingData
    for _, funcItem in pairs(systemFuncBlockingConf) do
      if funcItem.entranceBlockingType and funcItem.entranceBlockingType ~= FunctionBanEnum.EntranceBlockingType.None then
        local functionDesc = functionEntranceMap[funcItem.func_id]
        systemBlockingData[string.format("%s(%d)", functionDesc and functionDesc or "", funcItem.func_id)] = true
      end
    end
  end
  return debugData
end

function FunctionBanManager:GetFunctionState(functionType, needMsg, autoPopMsg, extendTime)
  if self.functionStateDic[functionType] then
    local state = self.functionStateDic[functionType].banCount > 0
    if not state then
      extendTime = extendTime or 0
      if self.functionStateDic[functionType].lastUnbanTime + extendTime > _G.UpdateManager.Timestamp then
        state = true
      end
    end
    if state then
      local banMsg
      if needMsg then
        banMsg = self:GetBanMassage(functionType)
        if autoPopMsg then
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, banMsg)
        end
      end
      return state, banMsg
    end
  end
  return false
end

function FunctionBanManager:GetPlayerConditions()
  return self.playerConditionDic
end

function FunctionBanManager:GetBanIssuer(Type)
  local Cond, Priority
  for ConditionType, Conf in pairs(self.playerConditionDic) do
    if Conf.function_ban_list[Type + 1].function_ban_switch then
      if not Cond then
        Cond = ConditionType
        Priority = Conf.desc_priority
      elseif Priority < Conf.desc_priority then
        Cond = ConditionType
        Priority = Conf.desc_priority
      end
    end
  end
  return Cond
end

function FunctionBanManager:GetConditionCounterDic()
  return self.conditionCounterDic
end

function FunctionBanManager:GetConditionCounter(ConditionType)
  local Val = self.conditionCounterDic[ConditionType]
  return Val and Val > 0
end

function FunctionBanManager:HasConditionsOtherThan(Types)
  for Type, Count in pairs(self.conditionCounterDic) do
    if Count > 0 and not table.contains(Types, Type) then
      return true
    end
  end
  return false
end

function FunctionBanManager:AddPlayerConditionType(conditionType, tag)
  Log.Debug("FunctionBanManager:AddPlayerConditionType", table.getKeyName(Enum.PlayerConditionType, conditionType), tag)
  local key = conditionType
  if tag then
    key = string.format("%s-%s", key, tag)
  end
  if self.playerConditionDic[key] == nil then
    local cfg = DataConfigManager:GetFunctionBanConf(conditionType)
    if nil == cfg then
      Log.Error("AddPlayerConditionType \230\137\190\228\184\141\229\136\176 ConditionType \233\133\141\231\189\174", conditionType)
      return
    end
    local counterDic = self.conditionCounterDic
    if nil == counterDic[conditionType] then
      counterDic[conditionType] = 1
    else
      counterDic[conditionType] = counterDic[conditionType] + 1
    end
    self.playerConditionDic[key] = cfg
    self:AddFunctionState(cfg)
    if self.condTypeToCliEventMap[conditionType] then
      local event = self.condTypeToCliEventMap[conditionType]
      self:SendZoneClientEventReq(event, true, tag)
    end
    if self.eventDispatcher then
      self.eventDispatcher:SendEvent(FunctionBanModuleEvent.OnPlayerConditionTypeChanged, conditionType, self:GetConditionCounter(conditionType))
    end
  end
end

function FunctionBanManager:RemovePlayerConditionType(conditionType, tag, IsPreHandleUIBan)
  Log.Debug("FunctionBanManager:RemovePlayerConditionType", table.getKeyName(Enum.PlayerConditionType, conditionType), tag)
  local key = conditionType
  if tag then
    key = string.format("%s-%s", key, tag)
  end
  if self.playerConditionDic[key] == nil then
    return
  end
  local counterDic = self.conditionCounterDic
  if counterDic[conditionType] then
    counterDic[conditionType] = counterDic[conditionType] - 1
  else
    counterDic[conditionType] = 0
  end
  local cfg = self.playerConditionDic[key]
  self:RemoveFunctionState(cfg, IsPreHandleUIBan)
  self.playerConditionDic[key] = nil
  if self.condTypeToCliEventMap[conditionType] then
    local event = self.condTypeToCliEventMap[conditionType]
    self:SendZoneClientEventReq(event, false, tag)
  end
  if self.eventDispatcher then
    self.eventDispatcher:SendEvent(FunctionBanModuleEvent.OnPlayerConditionTypeChanged, conditionType, self:GetConditionCounter(conditionType))
  end
end

function FunctionBanManager:RegisterConditionTypeChangeListener(Caller, Handler)
  if self.eventDispatcher then
    self.eventDispatcher:AddEventListener(Caller, FunctionBanModuleEvent.OnPlayerConditionTypeChanged, Handler)
  end
end

function FunctionBanManager:UnRegisterConditionTypeChangeListener(Caller, Handler)
  if self.eventDispatcher then
    self.eventDispatcher:RemoveEventListener(Caller, FunctionBanModuleEvent.OnPlayerConditionTypeChanged, Handler)
  end
end

function FunctionBanManager:AddFunctionStateListener(functionType, caller, handler)
  if not functionType then
    Log.Error("FunctionBanManager:AddFunctionStateListener functionType is nil")
    return
  end
  if self.functionStateDic[functionType] then
    Log.Debug("AddFunctionStateListener", functionType)
    self.eventDispatcher:AddEventListener(caller, functionType, handler)
  end
end

function FunctionBanManager:RemoveFunctionStateListener(functionType, caller, handler)
  if not functionType then
    Log.Error("FunctionBanManager:RemoveFunctionStateListener functionType is nil")
    return
  end
  Log.Debug("FunctionBanManager:RemoveFunctionStateListener", functionType)
  self.eventDispatcher:RemoveEventListener(caller, functionType, handler)
end

function FunctionBanManager:AddRawFunctionStateListener(functionType, caller, handler)
  if not functionType then
    Log.Error("FunctionBanManager:AddRawFunctionStateListener functionType is nil")
    return
  end
  local Name = table.getKeyName(Enum.PlayerFunctionBanType, functionType)
  if string.IsNilOrEmpty(Name) then
    Log.Error("FunctionBanManager:AddRawFunctionStateListener functionType name is nil", functionType)
    return
  end
  Log.Debug("FunctionBanManager:AddRawFunctionStateListener", Name)
  self.eventDispatcher:AddEventListener(caller, Name, handler)
end

function FunctionBanManager:RemoveRawFunctionStateListener(functionType, caller, handler)
  if not functionType then
    Log.Error("FunctionBanManager:RemoveRawFunctionStateListener functionType is nil")
    return
  end
  local Name = table.getKeyName(Enum.PlayerFunctionBanType, functionType)
  if string.IsNilOrEmpty(Name) then
    Log.Error("FunctionBanManager:RemoveRawFunctionStateListener functionType name is nil", functionType)
    return
  end
  Log.Debug("FunctionBanManager:RemoveRawFunctionStateListener", Name)
  self.eventDispatcher:RemoveEventListener(caller, Name, handler)
end

function FunctionBanManager:InitializeFunctionBanNameMap()
  local Type2NameMap = {}
  for Name, Type in pairs(Enum.PlayerFunctionBanType) do
    Type2NameMap[Type] = Name
  end
  self.FunctionBanTypeNameMap = Type2NameMap
end

function FunctionBanManager:GetPlayerFunctionBanNameByType(Type)
  return Type and self.FunctionBanTypeNameMap[Type] or ""
end

function FunctionBanManager:AddFunctionState(cfg)
  local FunctionEntranceVisible = self:OnUIBanFunctionPreChanged(cfg.id)
  local function_ban_list = cfg.function_ban_list
  for index, value in ipairs(function_ban_list) do
    local Type = index - 1
    local Item = self.functionStateDic[Type]
    if not Item then
      Item = self:CreateFunctionState()
      self.functionStateDic[Type] = Item
    end
    if value.function_ban_switch then
      local oldBanCount = Item.banCount
      local newBanCount = Item.banCount + 1
      local RawName = self:GetPlayerFunctionBanNameByType(Type)
      Item.banCount = newBanCount
      if newBanCount > 0 and 0 == oldBanCount then
        self.eventDispatcher:SendEvent(Type, true, Type, cfg.id)
        self:TryInterruptOperation(Type)
      end
      self.eventDispatcher:SendEvent(RawName, true, Type, cfg.id)
    end
  end
  self:OnUIBanFunctionChanged(true, cfg.id, FunctionEntranceVisible)
end

function FunctionBanManager:RemoveFunctionState(cfg, IsPreHandleUIBan)
  local FunctionEntranceVisible = self:OnUIBanFunctionPreChanged(cfg.id)
  local function_ban_list = cfg.function_ban_list
  if IsPreHandleUIBan then
    self:OnUIBanFunctionChanged(false, cfg.id, FunctionEntranceVisible)
  end
  for index, value in ipairs(function_ban_list) do
    local Type = index - 1
    if value.function_ban_switch then
      local Item = self.functionStateDic[Type]
      local oldBanCount = Item.banCount
      local newBanCount = Item.banCount - 1
      local RawName = table.getKeyName(Enum.PlayerFunctionBanType, Type)
      if newBanCount < 0 then
        newBanCount = 0
      end
      Item.banCount = newBanCount
      if 0 == newBanCount and oldBanCount > 0 then
        self.eventDispatcher:SendEvent(Type, false, Type, cfg.id)
        Item.lastUnbanTime = _G.UpdateManager.Timestamp
      end
      self.eventDispatcher:SendEvent(RawName, false, Type, cfg.id)
    end
  end
  if not IsPreHandleUIBan then
    self:OnUIBanFunctionChanged(false, cfg.id, FunctionEntranceVisible)
  end
end

function FunctionBanManager:SendZoneClientEventReq(_event, _is_start, tag)
  if self.ReportEvtToServer == false then
    Log.Debug("Not ReportEvtToServer")
    return
  end
  Log.Debug("FunctionBanManager:SendZoneSceneClientEventReq", table.getKeyName(Enum.PlayerConditionType, tonumber(table.getKeyName(self.condTypeToCliEventMap, _event))), _is_start, tag)
  if not self.clientEventReq then
    self.clientEventReq = _G.ProtoMessage:newZoneSceneClientEventReq()
    table.insert(self.clientEventReq.client_event, _G.ProtoMessage:newClientEvent())
  end
  self.clientEventReq.client_event[1].event = _event
  self.clientEventReq.client_event[1].is_start = _is_start
  if tag then
    self.clientEventReq.client_event[1].tag = tag
  end
  local bSent = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_EVENT_REQ, self.clientEventReq, self, self.OnZoneClientEventRsp, false, true)
  if not bSent then
    Log.Error("FunctionBanManager:SendZoneSceneClientEventReq Can not send network cmd", table.getKeyName(Enum.PlayerConditionType, tonumber(table.getKeyName(self.condTypeToCliEventMap, _event))), _is_start, tag)
  end
end

function FunctionBanManager:OnZoneClientEventRsp(rsp)
  Log.Debug("FunctionBanManager:OnZoneClientEventRsp")
end

function FunctionBanManager:GetBanMassage(Type)
  local conditionDic = self.playerConditionDic
  local curDescPriority = -1
  local curDescMsg = ""
  for _, cfg in pairs(conditionDic) do
    local Banned = true
    if Type then
      local List = cfg.function_ban_list
      local Item = List[Type + 1]
      Banned = Item and Item.function_ban_switch
    end
    if Banned and curDescPriority < cfg.desc_priority then
      curDescPriority = cfg.desc_priority
      curDescMsg = cfg.ban_desc
    end
  end
  return curDescMsg
end

function FunctionBanManager:DumpFunctionStates()
  local valueToKey = {}
  local functionType = Enum.PlayerFunctionBanType
  for k, v in pairs(functionType) do
    valueToKey[v] = k
  end
  Log.Error("-- \229\189\147\229\137\141\229\144\132\229\138\159\232\131\189\233\148\129\229\174\154\231\138\182\230\128\129 End --")
  local endIdx = Enum.PlayerFunctionBanType.PFBT_END - 1
  local startIdx = Enum.PlayerFunctionBanType.PFBT_BEGIN + 1
  for i = endIdx, startIdx, -1 do
    Log.Error(string.format("%s = %d", valueToKey[i], self.functionStateDic[i] and self.functionStateDic[i].banCount or ""))
  end
  Log.Error("-- \229\189\147\229\137\141\229\144\132\229\138\159\232\131\189\233\148\129\229\174\154\231\138\182\230\128\129 Begin --")
end

function FunctionBanManager:DumpConditionTypes()
  local valueToKey = {}
  local conditionType = Enum.PlayerConditionType
  for k, v in pairs(conditionType) do
    valueToKey[v] = k
  end
  Log.Error("-- \229\189\147\229\137\141\231\142\169\229\174\182\231\138\182\230\128\129 End --")
  local conditionDic = self.playerConditionDic
  for key, cfg in pairs(conditionDic) do
    Log.Error(string.format("%s = %s", valueToKey[cfg.id], key))
  end
  Log.Error("-- \229\189\147\229\137\141\231\142\169\229\174\182\231\138\182\230\128\129 Begin --")
end

function FunctionBanManager:ClearAllConditions()
  local conditionDic = self.playerConditionDic
  for k, _ in pairs(conditionDic) do
    self:RemovePlayerConditionType(k)
  end
end

function FunctionBanManager:TryInterruptOperation(Type)
  if Type == _G.Enum.PlayerFunctionBanType.PFBT_COMPASS then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
  end
end

return FunctionBanManager
