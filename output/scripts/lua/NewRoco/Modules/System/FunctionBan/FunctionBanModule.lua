local FunctionBanModule = NRCModuleBase:Extend("FunctionBanModule")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local StatusCheckerEnum = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerEnum")
local StatusCheckerGroup = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerGroup")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local FunctionBanModuleEvent = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleEvent")
local FunctionBanEnum = require("NewRoco.Modules.System.FunctionBan.FunctionBanEnum")

local function CreateFuncEntranceRedPointData(_id, _extraKey)
  return {id = _id, extraKey = _extraKey}
end

function FunctionBanModule:OnConstruct()
  Log.Debug("FunctionBanModule:OnConstruct")
  _G.FunctionBanModuleCmd = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleCmd")
  self:RegisterCmd(_G.FunctionBanModuleCmd.OpenPanel, self.OnOpenPanel)
  self:RegisterCmd(_G.FunctionBanModuleCmd.ClosePanel, self.OnClosePanel)
  self:RegisterCmd(_G.FunctionBanModuleCmd.AddCondition, self.OnAddCondition)
  self:RegisterCmd(_G.FunctionBanModuleCmd.RemoveCondition, self.OnRemoveCondition)
  self:RegisterCmd(_G.FunctionBanModuleCmd.GetFunctionState, self.OnGetFunctionState)
  self:RegisterCmd(_G.FunctionBanModuleCmd.DumpFunctionStates, self.OnDumpFunctionStates)
  self:RegisterCmd(_G.FunctionBanModuleCmd.DumpConditionTypes, self.OnDumpConditionTypes)
  self:RegisterCmd(_G.FunctionBanModuleCmd.ClientEventResume, self.OnClientEventResume)
  self:RegisterCmd(_G.FunctionBanModuleCmd.RegisterUIResumeCmd, self.OnRegisterUIResumeCmd)
  self:RegisterCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, self.OnCheckUIFunctionBan)
  self:RegisterCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, self.OnCheckUIFunctionHide)
  self:RegisterCmd(_G.FunctionBanModuleCmd.GmSkipCheckUIFunctionBan, self.OnGmSkipCheckUIFunctionBan)
  self:RegisterCmd(_G.FunctionBanModuleCmd.PlayUnlockUIShowByEnum, self.PlayUnlockUIShowByEnum)
  self:RegisterCmd(_G.FunctionBanModuleCmd.RemoveUnlockUIShowByEnum, self.RemoveUnlockUIShowByEnum)
  self:RegisterCmd(_G.FunctionBanModuleCmd.AddFuncEntranceConstraints, self.AddFuncEntranceConstraints)
  self:RegisterCmd(_G.FunctionBanModuleCmd.RemoveFuncEntranceConstraints, self.RemoveFuncEntranceConstraints)
  self:RegisterCmd(_G.FunctionBanModuleCmd.CheckIfUIFuncVisibilityChange, self.CheckIfUIFuncVisibilityChange)
  self:RegisterCmd(_G.FunctionBanModuleCmd.RegisterFunctionEntranceRedPoint, self.RegisterFunctionEntranceRedPoint)
  self:RegisterCmd(_G.FunctionBanModuleCmd.UnregisterFunctionEntranceRedPoint, self.UnregisterFunctionEntranceRedPoint)
  self:RegisterCmd(_G.FunctionBanModuleCmd.IsFunctionEntranceUnLocked, self.IsFunctionEntranceUnLocked)
  self:RegisterCmd(_G.FunctionBanModuleCmd.SetSkipRedPointBanLogic, self.SetSkipRedPointBanLogic)
  self.bSkipRedPointBanLogic = false
  self.unlocked_ui_table = {}
  self.playedUnlockTipUI = {}
  self.functionBanLockedUI = {}
  self.functionEntranceLogicConstraints = {}
  self.functionEntranceRedPointConf = {}
  self.UICmdDic = {}
  self:AddEventListener()
  self.cachedUIEnumShow = {}
end

function FunctionBanModule:OnDestruct()
  _G.FunctionBanManager:ClearAll()
  self:RemoveEventListener()
  self.cachedUIEnumShow = {}
  self.UICmdDic = nil
end

function FunctionBanModule:AddEventListener()
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCPanelEvent.OpenPanel, self.OnOpenPanel)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.OnTeleportNotify, self.OnTeleportStart)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnEnterSceneFinish)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.BigWorldPrepared, self.SyncClientEvents)
  _G.NRCEventCenter:RegisterEvent(self.name, self, FunctionBanModuleEvent.OnSystemFuncBlockingTypeChange, self.OnSystemFuncBlockingTypeChangeHandler)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.STORY_FLAG_ADDED, self.OnTryUnlockUI)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.PLAYER_EXP_CHANGED, self.OnTryUnlockUI)
  _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_WORLDCHANGE, self, self.OnWorldChange)
end

function FunctionBanModule:RemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.OpenPanel, self.OnOpenPanel)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnTeleportNotify, self.OnTeleportStart)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnEnterSceneFinish)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.BigWorldPrepared, self.SyncClientEvents)
  _G.NRCEventCenter:UnRegisterEvent(self, FunctionBanModuleEvent.OnSystemFuncBlockingTypeChange, self.OnSystemFuncBlockingTypeChangeHandler)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.STORY_FLAG_ADDED, self.OnTryUnlockUI)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.PLAYER_EXP_CHANGED, self.OnTryUnlockUI)
  _G.FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_WORLDCHANGE, self, self.OnWorldChange)
end

function FunctionBanModule:OnLogin(isReLogin)
  if self.hasInitFunctionBanData then
    return
  end
  self.hasInitFunctionBanData = true
  self:CalculateUnlockedUI()
  self:InitFunctionEntranceRedPointState()
end

function FunctionBanModule:OnWorldChange(Banned, Type)
end

function FunctionBanModule:OnTeleportStart(samescene)
  _G.FunctionBanManager:AddPlayerConditionType(Enum.PlayerConditionType.PCT_TELEPORT)
end

function FunctionBanModule:OnEnterSceneFinish()
  Log.Debug("FunctionBan OnLoadMapEnd")
  _G.FunctionBanManager:RemovePlayerConditionType(Enum.PlayerConditionType.PCT_TELEPORT)
end

function FunctionBanModule:SyncClientEvents()
  local Req = _G.ProtoMessage:newZoneSceneClientEventReq()
  local NeedSend = false
  local LayerCenter = _G.NRCPanelManager and _G.NRCPanelManager.layerCenter
  local FullScreenLayer = LayerCenter and LayerCenter:GetLayerCtrl(Enum.UILayerType.UI_LAYER_FULLSCREEN)
  if FullScreenLayer then
    local Windows = FullScreenLayer:GetAllWindow()
    for _, Panel in ipairs(Windows) do
      if Panel:GetIsVisible() and Panel:GetIsEnabled() then
        local Event = _G.ProtoMessage:newClientEvent()
        Event.is_start = true
        Event.event = Enum.ClientEvent.CE_UI_FULL_SCENE
        Event.tag = Panel.panelData.panelName
        table.insert(Req.client_event, Event)
        NeedSend = true
      end
    end
  end
  local CinematicPlaying = _G.CinematicModuleCmd and _G.NRCModuleManager:DoCmd(_G.CinematicModuleCmd.IsPlaying) or false
  if CinematicPlaying then
    local Event = _G.ProtoMessage:newClientEvent()
    Event.is_start = true
    Event.event = Enum.ClientEvent.CE_CG
    table.insert(Req.client_event, Event)
    NeedSend = true
  end
  if not NeedSend then
    return
  end
  if #Req.client_event > 0 then
    local bSent = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_EVENT_REQ, Req, self, self.OnZoneClientEventRsp, false, true)
    if not bSent then
      Log.Error("FunctionBanModule:SyncClientEvents Can not send network cmd", #Req.client_event, Req.client_event[1].is_start, Req.client_event[1].event, Req.client_event[1].tag)
    end
  end
end

function FunctionBanModule:OnZoneClientEventRsp(rsp)
  Log.Debug("FunctionBanModule:OnZoneClientEventRsp")
end

function FunctionBanModule:OnGetFunctionState(functionType, needMsg, autoPopMsg)
  return _G.FunctionBanManager:GetFunctionState(functionType, needMsg, autoPopMsg)
end

function FunctionBanModule:OnAddCondition(conditionType, tag)
  _G.FunctionBanManager:AddPlayerConditionType(conditionType, tag)
end

function FunctionBanModule:OnRemoveCondition(conditionType, tag, IsPreHandleUIBan)
  _G.FunctionBanManager:RemovePlayerConditionType(conditionType, tag, IsPreHandleUIBan)
end

function FunctionBanModule:OnOpenPanel(panelData)
  if panelData.panelLayer == _G.Enum.UILayerType.UI_LAYER_FULLSCREEN then
    _G.FunctionBanManager:AddPlayerConditionType(_G.Enum.PlayerConditionType.PCT_FULLSCREEN_UI, panelData.panelName)
    Log.Debug("FunctionBanModule:OnOpenPanel", panelData.panelName)
  end
end

function FunctionBanModule:OnClosePanel(panelData)
  if panelData.panelLayer == _G.Enum.UILayerType.UI_LAYER_FULLSCREEN then
    _G.FunctionBanManager:RemovePlayerConditionType(_G.Enum.PlayerConditionType.PCT_FULLSCREEN_UI, panelData.panelName)
    Log.Debug("FunctionBanModule:OnClosePanel", panelData.panelName)
  end
end

function FunctionBanModule:OnRegisterUIResumeCmd(uiName, cmd)
  if not uiName then
    Log.Error("\230\179\168\229\134\140UIResume\231\154\132uiName\228\184\141\232\131\189\228\184\186\231\169\186", uiName)
    return
  end
  self.UICmdDic[uiName] = cmd
end

function FunctionBanModule:AddFuncEntranceConstraints(Reason, FunctionEntrance, ConstraintFunc)
  if not self.functionEntranceLogicConstraints[FunctionEntrance] then
    self.functionEntranceLogicConstraints[FunctionEntrance] = {}
  end
  self.functionEntranceLogicConstraints[FunctionEntrance][ConstraintFunc] = Reason or true
end

function FunctionBanModule:RemoveFuncEntranceConstraints(FunctionEntrance, ConstraintFunc)
  if not FunctionEntrance or not ConstraintFunc then
    Log.Error("FunctionBan RemoveFuncEntranceConstraints invalid params")
    return
  end
  if not self.functionEntranceLogicConstraints[FunctionEntrance] then
    Log.Error("FunctionBan RemoveFuncEntranceConstraints cannot found entrance constraints", FunctionEntrance, ConstraintFunc)
    return
  end
  self.functionEntranceLogicConstraints[FunctionEntrance][ConstraintFunc] = nil
end

function FunctionBanModule:IfFuncEntranceConstraint(FunctionEntrance)
  if not FunctionEntrance then
    return true
  end
  local Constraints = self.functionEntranceLogicConstraints[FunctionEntrance]
  if not Constraints or not next(Constraints) then
    return false
  end
  for Constraint, v in pairs(Constraints) do
    if Constraint() then
      Log.Debug("FunctionBan function entrance constraint by", v)
      return true
    end
  end
  return false
end

function FunctionBanModule:InitFunctionEntranceRedPointState()
  if NRCEnv:IsLocalMode() then
    return
  end
  local allConf = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.SYSTEM_RED_POINT_BAN_CONF)
  if not allConf or not next(allConf) then
    return
  end
  for _, conf in pairs(allConf) do
    local isBan = self:OnCheckUIFunctionBan(conf.id, false)
    if isBan then
      for _, redPointId in ipairs(conf.redpoint_id) do
        _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.InvalidPointData, redPointId)
      end
    end
  end
end

function FunctionBanModule:OnSystemFuncBlockingTypeChangeHandler(funcId, entranceBlockingType)
  self:CheckIfUIFuncVisibilityChange(funcId)
end

function FunctionBanModule:CheckIfUIFuncVisibilityChange(uiFunctionId, bHideCached)
  local bHide = self:OnCheckUIFunctionHide(uiFunctionId)
  if bHideCached and bHideCached == bHide then
    return bHide
  end
  _G.NRCEventCenter:DispatchEvent(FunctionBanModuleEvent.OnUIFuncVisibilityChange, uiFunctionId, bHide)
  if self.bSkipRedPointBanLogic == false then
    local redPointConfTable = self.functionEntranceRedPointConf[uiFunctionId]
    local sysRedPointConf = _G.DataConfigManager:GetSystemRedPointBanConf(uiFunctionId, true)
    if redPointConfTable or sysRedPointConf then
      local RedPointCmd = _G.RedPointModuleCmd.InvalidPointData
      if not bHide and not self:OnCheckUIFunctionBan(uiFunctionId, false) then
        RedPointCmd = _G.RedPointModuleCmd.RecoverPointData
      end
      if redPointConfTable then
        for _, redPointConf in ipairs(redPointConfTable) do
          _G.NRCModuleManager:DoCmd(RedPointCmd, redPointConf.id, redPointConf.extraKey)
        end
      end
      if sysRedPointConf then
        for _, redPointId in ipairs(sysRedPointConf.redpoint_id) do
          _G.NRCModuleManager:DoCmd(RedPointCmd, redPointId)
        end
      end
    end
  end
  return bHide
end

function FunctionBanModule:RegisterFunctionEntranceRedPoint(uiFunctionId, redPointId, redPointExtraKey)
  if not uiFunctionId or not redPointId then
    return
  end
  local redPointConfTable = self.functionEntranceRedPointConf[uiFunctionId]
  if not redPointConfTable then
    redPointConfTable = {
      CreateFuncEntranceRedPointData(redPointId, redPointExtraKey)
    }
    self.functionEntranceRedPointConf[uiFunctionId] = redPointConfTable
  else
    for _, redPointConf in ipairs(redPointConfTable) do
      if redPointConf.id == redPointId then
        return
      end
    end
    table.insert(redPointConfTable, CreateFuncEntranceRedPointData(redPointId, redPointExtraKey))
  end
  local isBan = self:OnCheckUIFunctionBan(uiFunctionId, false)
  if isBan then
    _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.InvalidPointData, redPointId, redPointExtraKey)
  end
end

function FunctionBanModule:UnregisterFunctionEntranceRedPoint(uiFunctionId, redPointId, redPointExtraKey)
  if not uiFunctionId or not redPointId then
    return
  end
  local redPointConfTable = self.functionEntranceRedPointConf[uiFunctionId]
  if redPointConfTable then
    for index, redPointConf in ipairs(redPointConfTable) do
      if redPointConf.id == redPointId then
        table.remove(redPointConfTable, index)
        if 0 == #redPointConfTable then
          self.functionEntranceRedPointConf[uiFunctionId] = nil
        end
        local isBan = self:OnCheckUIFunctionBan(uiFunctionId, false)
        if isBan then
          _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.RecoverPointData, redPointId, redPointExtraKey)
        end
        return
      end
    end
  end
end

function FunctionBanModule:OnClientEventResume(notify)
  if not notify then
    return
  end
  if notify and notify.event == _G.Enum.ClientEvent.CE_UI_FULL_SCENE or notify.event == _G.Enum.ClientEvent.CE_UI_NOT_FULL_SCENE then
    self.cachedUIResumeTags = notify.tag
    if self.statusChecker == nil then
      self.statusChecker = StatusCheckerGroup({
        StatusCheckerEnum.MainPanel
      })
    end
    self.statusChecker:Check(self, self.ResumeUI)
  end
end

function FunctionBanModule:ResumeUI()
  if self.cachedUIResumeTags then
    local tags = self.cachedUIResumeTags
    for _, tag in ipairs(tags) do
      local cmd = self.UICmdDic[tag]
      if not cmd then
        Log.Warning("\230\178\161\230\156\137\230\179\168\229\134\140\230\129\162\229\164\141\231\154\132Cmd", tag)
      else
        _G.NRCModuleManager:DoCmd(cmd)
      end
    end
    self.cachedUIResumeTags = nil
  end
end

local function _CheckRoleLevelMet(cond)
  local needLevel = tonumber(cond.unlock_param and cond.unlock_param[1] or 0)
  local heroLv = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel() or 0
  local isMet = needLevel <= heroLv
  local banMsg
  if not isMet then
    banMsg = string.format(cond.ban_text, needLevel)
  end
  return needLevel <= heroLv, banMsg
end

local function _CheckStoryFlagMet(cond)
  local flags = cond.unlock_param
  local isMet = false
  local PlayerDataModel = _G.DataModelMgr.PlayerDataModel
  for _, flag in ipairs(flags) do
    local flagNum = tonumber(flag)
    if PlayerDataModel:HasStoryFlag(flagNum) then
      isMet = true
      break
    end
  end
  local banMsg
  if not isMet then
    banMsg = cond.ban_text
  end
  return isMet, banMsg
end

local function _CheckWorldLevelMet(cond)
  local worldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  local needLevel = tonumber(cond.unlock_param and cond.unlock_param[1] or 0)
  local isMet = worldLevel >= needLevel
  local banMsg
  if not isMet then
    if cond.ban_text then
      banMsg = string.format(cond.ban_text, needLevel)
    else
      Log.Warning("_CheckWorldLevelMet cond.ban_text is nil")
    end
  end
  return isMet, banMsg
end

local function _CheckUIEnterBanMet(cond)
  local isMet = true
  local banMsg
  local functionIds = cond.unlock_param or {}
  for _, _idStr in ipairs(functionIds) do
    local _id = tonumber(_idStr)
    if _id then
      local isBan, msg = _G.FunctionBanManager:GetFunctionState(_id, true, false)
      if isBan then
        isMet = false
        banMsg = msg
        break
      end
    end
  end
  if not isMet and not banMsg then
    banMsg = cond.ban_text
  end
  return isMet, banMsg
end

local _CondCheckFuncDic = {
  [_G.Enum.EntranceUnlockCondition.EUC_ROLE_LEVEL] = _CheckRoleLevelMet,
  [_G.Enum.EntranceUnlockCondition.EUC_STORY_FLAG] = _CheckStoryFlagMet,
  [_G.Enum.EntranceUnlockCondition.EUC_WORLD_LEVEL] = _CheckWorldLevelMet,
  [_G.Enum.EntranceUnlockCondition.EUC_UI_ENTER_BAN_CONF] = _CheckUIEnterBanMet
}

function FunctionBanModule:OnCheckUIFunctionBan(uiFunctionId, autoPopMsg, onlyCheckSvr)
  local funcBlockingType = _G.FunctionBanManager:GetFuncBlockingStateBySvrData(uiFunctionId)
  if funcBlockingType then
    local blockingMsg
    if funcBlockingType == FunctionBanEnum.EntranceBlockingType.NeedNewVersion then
      blockingMsg = _G.LuaText.onlinemodule_7 or ""
    elseif funcBlockingType == FunctionBanEnum.EntranceBlockingType.Lock then
      blockingMsg = _G.LuaText.onlinemodule_12 or ""
    elseif funcBlockingType ~= FunctionBanEnum.EntranceBlockingType.None then
      blockingMsg = _G.LuaText.onlinemodule_12 or ""
    end
    if blockingMsg then
      if autoPopMsg then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, blockingMsg)
      end
      return true
    end
  end
  if onlyCheckSvr then
    return false
  end
  local cfg = _G.DataConfigManager:GetUiEnterBanConf(uiFunctionId, true)
  if not cfg then
    return false
  end
  if not self.gmSkipCheckUIFunctionBan then
    for _, cond in ipairs(cfg.unlock_cond_list) do
      local checkMetFunc = _CondCheckFuncDic[cond.unlock_type]
      if checkMetFunc then
        local isMet, banMsg = checkMetFunc(cond)
        if not isMet then
          if autoPopMsg then
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, banMsg)
          end
          return true
        end
      end
    end
  end
  if cfg.function_Ban_Type then
    local Forbidden = _G.FunctionBanManager:GetFunctionState(cfg.function_Ban_Type, true, autoPopMsg)
    if Forbidden then
      return true
    end
  end
  return false
end

function FunctionBanModule:OnCheckUIFunctionHide(uiFunctionId, LogReason, onlyCheckSvr)
  local funcBlockingType = _G.FunctionBanManager:GetFuncBlockingStateBySvrData(uiFunctionId)
  if funcBlockingType == FunctionBanEnum.EntranceBlockingType.Hide then
    if LogReason then
      Log.Debug("FunctionBan UIBan func=", uiFunctionId, "svr blocking")
    end
    return true
  end
  if onlyCheckSvr then
    return false
  end
  local cfg = _G.DataConfigManager:GetUiEnterBanConf(uiFunctionId, true)
  if cfg then
    for _, cond in ipairs(cfg.unlock_cond_list) do
      local checkMetFunc = _CondCheckFuncDic[cond.unlock_type]
      if checkMetFunc then
        local isMet, banMsg = checkMetFunc(cond)
        if not isMet and cfg and cfg.is_hide_entrance == true then
          if LogReason then
            Log.Debug("FunctionBan UIBan func=", uiFunctionId, "condition failed", cond.unlock_type)
          end
          return true
        end
      end
    end
    if cfg.function_Ban_Type and cfg.is_hide_entrance then
      local Forbidden, BanMsg = _G.FunctionBanManager:GetFunctionState(cfg.function_Ban_Type, false, false)
      if Forbidden then
        if LogReason then
          Log.Debug("FunctionBan UIBan func=", uiFunctionId, "function ban", cfg.function_Ban_Type)
        end
        return true
      end
    end
  end
  local bIsForbidden = _G.FunctionBanManager:OnCheckUIBanForbidden(uiFunctionId)
  if bIsForbidden then
    if LogReason then
      Log.Debug("FunctionBan UIBan func=", uiFunctionId, "ui ban")
    end
    return true
  end
  local bIsConstraints = self:IfFuncEntranceConstraint(uiFunctionId)
  if bIsConstraints then
    if LogReason then
      Log.Debug("FunctionBan UIBan func=", uiFunctionId, "custom")
    end
    return true
  end
  return false
end

function FunctionBanModule:OnGmSkipCheckUIFunctionBan()
  self.gmSkipCheckUIFunctionBan = true
end

function FunctionBanModule:CalculateUnlockedUI()
  if NRCEnv:IsLocalMode() then
    return
  end
  self.unlocked_ui_table = {}
  local UIEnterBanData = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.UI_ENTER_BAN_CONF):GetAllDatas()
  self.UiVisibilityByFunctionBan = {}
  local AdditionFunctions = {}
  for _, data in pairs(UIEnterBanData) do
    if 0 ~= (data.function_Ban_Type or 0) then
      if not AdditionFunctions[data.function_Ban_Type] then
        AdditionFunctions[data.function_Ban_Type] = true
        Log.Debug("FunctionBan RegisterUIBan with function ban", data.id, data.function_Ban_Type)
        _G.FunctionBanManager:AddFunctionStateListener(data.function_Ban_Type, self, self.OnUIVisibilityChangeByFunctionBan)
      end
      local Entrances = self.UiVisibilityByFunctionBan[data.function_Ban_Type]
      if not Entrances then
        Entrances = {}
        self.UiVisibilityByFunctionBan[data.function_Ban_Type] = Entrances
      end
      table.insert(Entrances, data.id)
    end
  end
  for _, data in pairs(UIEnterBanData) do
    local item = data
    for _, unlock_data in ipairs(item.unlock_cond_list) do
      local checkMetFunc = _CondCheckFuncDic[unlock_data.unlock_type]
      if checkMetFunc then
        local isMet, banMsg = checkMetFunc(unlock_data)
        if not isMet then
          self.unlocked_ui_table[item.id] = true
          break
        end
      end
    end
    for _, unlock_data in ipairs(item.unlock_cond_list) do
      if unlock_data.unlock_type == Enum.EntranceUnlockCondition.EUC_UI_ENTER_BAN_CONF then
        local functionIds = unlock_data.unlock_param or {}
        for _, _functionTypeStr in ipairs(functionIds) do
          local _functionType = tonumber(_functionTypeStr)
          if _functionType then
            self.functionBanLockedUI[_functionType] = item.id
            _G.FunctionBanManager:AddFunctionStateListener(_functionType, self, self.OnUnlockedUIFunctionStateChange)
          end
        end
      end
    end
  end
end

function FunctionBanModule:OnTryUnlockUI()
  local unlocked_ids = {}
  for id, _ in pairs(self.unlocked_ui_table) do
    local item = _G.DataConfigManager:GetUiEnterBanConf(id)
    for _, unlock_data in ipairs(item.unlock_cond_list) do
      local checkMetFunc = _CondCheckFuncDic[unlock_data.unlock_type]
      if checkMetFunc then
        local isMet, banMsg = checkMetFunc(unlock_data)
        if not isMet then
          goto lbl_67
        end
      end
    end
    local Tip
    if not table.contains(self.playedUnlockTipUI, id) then
      Tip = TipObject.CreateUnlockUIEnumTip(id)
    end
    if Tip then
      if item.auto_perform then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_ShowPropTips, Tip, "UIUnlock")
      else
        self.cachedUIEnumShow[item.id] = Tip
      end
    end
    table.insert(unlocked_ids, id)
    self.playedUnlockTipUI[id] = true
    ::lbl_67::
  end
  for _, unlock_id in ipairs(unlocked_ids) do
    self.unlocked_ui_table[unlock_id] = nil
    _G.NRCEventCenter:DispatchEvent(FunctionBanModuleEvent.OnUIEnterBanStateChange, unlock_id, false)
    self:CheckIfUIFuncVisibilityChange(unlock_id)
  end
end

function FunctionBanModule:OnTryLockUI(id)
  if not id then
    return
  end
  if not table.contains(self.unlocked_ui_table, id) then
    self.unlocked_ui_table[id] = true
    _G.NRCEventCenter:DispatchEvent(FunctionBanModuleEvent.OnUIEnterBanStateChange, id, true)
    self:CheckIfUIFuncVisibilityChange(id)
  end
end

function FunctionBanModule:IsFunctionEntranceUnLocked(Entrance)
  return Entrance and not self.unlocked_ui_table[Entrance]
end

function FunctionBanModule:SetSkipRedPointBanLogic(bSkip)
  self.bSkipRedPointBanLogic = bSkip
end

function FunctionBanModule:OnUnlockedUIFunctionStateChange(isBan, functionType)
  if isBan then
    self:OnTryLockUI(self.functionBanLockedUI[functionType])
  else
    self:OnTryUnlockUI()
  end
end

function FunctionBanModule:OnUIVisibilityChangeByFunctionBan(isBan, functionType)
  Log.Debug("FunctionBan OnUIVisibilityChangeByFunctionBan", isBan, functionType)
  local Entrances = self.UiVisibilityByFunctionBan[functionType]
  if Entrances then
    for i, Entrance in ipairs(Entrances) do
      local bHide = self:CheckIfUIFuncVisibilityChange(Entrance)
      Log.Debug("FunctionBan OnUIVisibilityChangeByFunctionBan Entrance", Entrance, bHide)
    end
  end
end

function FunctionBanModule:PlayUnlockUIShowByEnum(UnlockUIEnum)
  if self.cachedUIEnumShow[UnlockUIEnum] then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_ShowPropTips, self.cachedUIEnumShow[UnlockUIEnum], "UIUnlock")
    self.cachedUIEnumShow[UnlockUIEnum] = nil
  end
end

function FunctionBanModule:RemoveUnlockUIShowByEnum(UnlockUIEnum)
  self.cachedUIEnumShow[UnlockUIEnum] = nil
end

function FunctionBanModule:CheckDungeonUIBan()
  local OldDungeonID = self.FuncBanRecordDungeonID or 0
  local DungeonID = DataModelMgr.PlayerDataModel:GetDungeonID() or 0
  if OldDungeonID ~= DungeonID then
    Log.Info("FunctionBan CheckDungeonUIBan", OldDungeonID, DungeonID)
    self.FuncBanRecordDungeonID = DungeonID
    if 0 ~= OldDungeonID then
      local DungeonConf = DataConfigManager:GetDungeonConf(OldDungeonID)
      if DungeonConf and 0 ~= (DungeonConf.function_ban_id or 0) then
        Log.Debug("FunctionBan CheckDungeonUIBan remove", DungeonConf.function_ban_id)
        self:OnRemoveCondition(DungeonConf.function_ban_id, "Dungeon_" .. OldDungeonID)
      end
    end
    if 0 ~= DungeonID then
      local DungeonConf = DataConfigManager:GetDungeonConf(DungeonID)
      if DungeonConf and 0 ~= (DungeonConf.function_ban_id or 0) then
        Log.Debug("FunctionBan CheckDungeonUIBan insert", DungeonConf.function_ban_id)
        self:OnAddCondition(DungeonConf.function_ban_id, "Dungeon_" .. DungeonID)
      end
    end
    Log.Info("FunctionBan CheckDungeonUIBan End", self.FuncBanRecordDungeonID)
  end
end

return FunctionBanModule
