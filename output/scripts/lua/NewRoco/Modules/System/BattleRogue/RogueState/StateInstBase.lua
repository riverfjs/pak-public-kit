local Class = _G.MakeSimpleClass
local RogueModuleEnum = require("NewRoco.Modules.System.BattleRogue.RogueModuleEnum")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local StateInstBase = Class("StateInstBase")
local StatePhase = {
  None = 0,
  PreEnter = 1,
  Enter = 2,
  Entered = 3,
  CanExit = 4,
  Exited = 5,
  Destroyed = 6
}
local FailedType = {
  None = 0,
  LoadFailed = 1,
  NoRespond = 2,
  RespondFailed = 3,
  CustomFailed = 4,
  Timeout = 5,
  Cancel = 6,
  AsyncError = 7
}

function StateInstBase:Ctor(State, ...)
  self.State = State
  self.Context = self:GetBindModule().Data
  self:SetPhase(StatePhase.None)
  self.bNeedCache = false
  self.Direction = 1
  self.ResRequests = nil
  self.StartAsyncRunning = false
  self.bCancelAsync = false
end

function StateInstBase:SetTransitionDirection(Direction)
  self.Direction = Direction
end

function StateInstBase:CanSwitchState()
  return true
end

function StateInstBase:GetBindModule()
  return _G.NRCModuleManager:GetModule("BattleRogueModule")
end

function StateInstBase:SetPhase(Phase)
  if self.StatePhase == Phase then
    self:WarningLog("already in this phase!")
    return
  end
  self.StatePhase = Phase
  self:DebugLog("SetPhase")
end

function StateInstBase:OnEnter()
end

function StateInstBase:OnEnterFailed(Reason)
end

function StateInstBase:OnReceiveRsp(Rsp)
end

function StateInstBase:OnReConnect()
end

function StateInstBase:OnExit()
end

function StateInstBase:GetPreLoadResList()
  return nil
end

function StateInstBase:GetServerReq()
  return nil, nil
end

function StateInstBase:GetCustomThunks()
  return nil
end

function StateInstBase:ValidateCustomResults(Results)
  return true
end

function StateInstBase:OnResReady(LoadedAssets, Rsp)
end

function StateInstBase:CancelAsyncOperations()
  self:DebugLog("CancelAsyncOperations!")
  self.bCancelAsync = true
  self:ClearAsyncBinds()
end

function StateInstBase:PreEnter()
  self:SetPhase(StatePhase.PreEnter)
  self.StartAsyncRunning = true
  local PreLoadList = self:GetPreLoadResList()
  local HasRes = PreLoadList and next(PreLoadList) ~= nil
  local ReqCmd, ReqMsg = self:GetServerReq()
  local HasSubmit = nil ~= (ReqCmd and ReqMsg)
  local CustomThunks = self:GetCustomThunks()
  local HasCustom = CustomThunks and next(CustomThunks) ~= nil
  if not HasRes and not HasSubmit and not HasCustom then
    return a.task(function()
      self:OnResReady()
      return FailedType.None
    end)
  end
  local Task = a.task(function()
    local Thunks = {}
    if HasRes then
      for Name, Path in pairs(PreLoadList) do
        Thunks[Name] = self:MakeResourceLoadFuture(Path)
      end
    end
    if HasSubmit then
      self.SubmitPromise = au.CreatePromise()
      Thunks.Submit = self.SubmitPromise.future
      self:SendSyncReq(ReqCmd, ReqMsg)
    end
    if HasCustom then
      for Name, Thunk in pairs(CustomThunks) do
        Thunks[Name] = Thunk
      end
    end
    local Results = a.wait_all(Thunks, true)
    local LoadedAssets
    if HasRes then
      local Ok, Msg
      LoadedAssets, Ok, Msg = self:CollectLoadedAssets(Results, PreLoadList)
      if not Ok then
        return FailedType.LoadFailed, Msg
      end
    end
    local Rsp
    if HasSubmit then
      local SubmitRet = Results.Submit
      if not SubmitRet then
        return FailedType.NoRespond
      end
      Rsp = SubmitRet[2]
      if not (SubmitRet[1] and Rsp and Rsp.ret_info) or 0 ~= Rsp.ret_info.ret_code then
        return FailedType.RespondFailed
      end
    end
    if HasCustom and not self:ValidateCustomResults(Results) then
      return FailedType.CustomFailed
    end
    self:OnResReady(LoadedAssets, Rsp)
    return FailedType.None
  end)
  return Task
end

function StateInstBase:MakeResourceLoadFuture(Path)
  if not Path or "" == Path then
    return function(cb)
      cb(true)
    end
  end
  local Req = _G.NRCResourceManager:LoadResAsync(self, Path, _G.PriorityEnum.Local_Player_Perform, 0)
  if not self.ResRequests then
    self.ResRequests = _G.MakeWeakTable()
  end
  table.insert(self.ResRequests, Req)
  return au.ResRequestCallback(Req)
end

function StateInstBase:CollectLoadedAssets(Results, ResList)
  if not ResList then
    return nil, false
  end
  local LoadedAssets = {}
  for Name, Path in pairs(ResList) do
    local LoadRet = Results[Name]
    if not LoadRet then
      return nil, false, Name
    end
    local Ok = LoadRet[1]
    local Asset = LoadRet[3]
    if not Ok then
      return nil, false, Path
    end
    LoadedAssets[Name] = Asset
  end
  return LoadedAssets, true
end

function StateInstBase:OnDoEnter()
end

function StateInstBase:DoEnter()
  if self.StartAsyncRunning then
    return
  end
  self:OnDoEnter()
  self.AsyncTaskContext = au.LaunchWithTimeout(self:PreEnter(), 5, function(NoUncheckedError, ResultType, Msg)
    if NoUncheckedError then
      self:FinishEnterAsync(ResultType or FailedType.None, Msg)
    else
      local Reason
      if self.bCancelAsync then
        Reason = FailedType.Cancel
      else
        Reason = FailedType.AsyncError
      end
      self:FinishEnterAsync(Reason, Msg or ResultType)
    end
  end)
end

function StateInstBase:FinishEnterAsync(Reason, Msg)
  if Reason and Reason ~= FailedType.None then
    if Reason ~= FailedType.Cancel then
      self:ErrorLog(string.format("EnterAsync Failed: %s    %s", table.getKeyName(FailedType, Reason), Msg))
      self:OnEnterFailed(Reason)
    else
      self:WarningLog("EnterAsync Canceled")
    end
    self:ClearAsyncBinds()
    return
  end
  self:DebugLog("DoEnter Success")
  self:InternalOnEnter()
  self:ClearAsyncBinds()
end

function StateInstBase:SendSyncReq(NetSyncCmd, NetSyncReq)
  if not NetSyncCmd or not NetSyncReq then
    self:WarningLog("NetSyncCmd or NetSyncReq is nil")
    return
  end
  self:DebugLog("SendSyncReq")
  _G.ZoneServer:SendWithHandler(NetSyncCmd, NetSyncReq, self, self.InternalOnReceiveSyncRsp, false, false)
end

function StateInstBase:InternalOnReceiveSyncRsp(Rsp)
  if self.SubmitPromise then
    self.SubmitPromise.resolve(Rsp)
    self.SubmitPromise = nil
  end
  self:DebugLog("OnReceiveSyncRsp")
  self:OnReceiveRsp(Rsp)
end

function StateInstBase:ClearAsyncBinds()
  if self.AsyncTaskContext then
    a.kill(self.AsyncTaskContext)
    self.AsyncTaskContext = nil
  end
  if self.ResRequests then
    for _, Req in ipairs(self.ResRequests) do
      _G.NRCResourceManager:UnLoadRes(Req)
    end
    self.ResRequests = nil
  end
  self.StartAsyncRunning = false
  self.SubmitPromise = nil
  self.bCancelAsync = false
end

function StateInstBase:InternalOnEnter()
  self:DebugLog("OnEnter")
  self:SetPhase(StatePhase.Enter)
  self:OnEnter()
  self:SetPhase(StatePhase.Entered)
end

function StateInstBase:DoExit()
  if self.StatePhase == StatePhase.PreEnter then
    self:WarningLog("DoExit called during PreEnter phase, canceling async operations")
    self:CancelAsyncOperations()
  end
  self:InternalExit()
end

function StateInstBase:InternalExit()
  self:SetPhase(StatePhase.CanExit)
  self:OnExit()
  self:SetPhase(StatePhase.Exited)
end

function StateInstBase:Tick()
end

function StateInstBase:Destroy()
  self:DebugLog("Destroy")
  self:CancelAsyncOperations()
end

function StateInstBase:Pause()
  self:DebugLog("Pause")
end

function StateInstBase:Resume()
  self:DebugLog("Resume")
end

function StateInstBase:Refresh()
  self:DebugLog("Refresh")
  self:SetPhase(StatePhase.None)
  self.bNeedCache = false
  self.Direction = 1
  self.ResRequests = nil
  self.StartAsyncRunning = false
  self.bCancelAsync = false
end

function StateInstBase:CheckRspValid(RetInfo)
  local bValid = RetInfo and 0 == RetInfo.ret_code or false
  if not bValid then
    self:ErrorLog("Rsp is invalid")
  end
  return bValid
end

function StateInstBase:OpenPanel(PanelName, ...)
  local BindModule = self:GetBindModule()
  if not BindModule then
    return
  end
  if BindModule:HasPanel(PanelName) then
    local Panel = BindModule:GetPanel(PanelName)
    if Panel then
      local panelData = Panel.panelData
      if panelData and panelData.panelLayer == Enum.UILayerType.UI_LAYER_FULLSCREEN then
        local layerCtrl = _G.NRCPanelManager:GetLayerCtrl(panelData.panelLayer)
        if layerCtrl then
          local windowData = layerCtrl:GetWindowData(panelData.panelName)
          if windowData then
            layerCtrl:UnDoFoldSpecifiedWindow(windowData)
            if Panel.OnPanelShow then
              Panel:OnPanelShow()
            end
          end
        end
      end
      Panel:SetPanelAlreadyVisible()
    end
  else
    BindModule:OpenPanel(PanelName, ...)
  end
end

function StateInstBase:HidePanel(PanelName)
  local BindModule = self:GetBindModule()
  if not BindModule then
    return
  end
  if BindModule:HasPanel(PanelName) then
    local Panel = BindModule:GetPanel(PanelName)
    if Panel then
      Panel:SetPanelReadyToClosed()
      self:FoldPanelInternal(Panel)
    end
  end
end

function StateInstBase:FoldPanel(PanelName)
  local BindModule = self:GetBindModule()
  if not BindModule then
    return
  end
  if BindModule:HasPanel(PanelName) then
    local Panel = BindModule:GetPanel(PanelName)
    if Panel then
      self:FoldPanelInternal(Panel)
    end
  end
end

function StateInstBase:FoldPanelInternal(Panel)
  local panelData = Panel.panelData
  if panelData and panelData.panelLayer == Enum.UILayerType.UI_LAYER_FULLSCREEN then
    local layerCtrl = _G.NRCPanelManager:GetLayerCtrl(panelData.panelLayer)
    if layerCtrl then
      local windowData = layerCtrl:GetWindowData(panelData.panelName)
      if windowData then
        layerCtrl:DoFoldSpecifiedWindow(windowData)
      end
    end
  end
end

function StateInstBase:ClosePanel(PanelName)
  local BindModule = self:GetBindModule()
  if BindModule and BindModule:HasPanel(PanelName) then
    BindModule:ClosePanel(PanelName)
  end
end

local FlowPanelNames = {
  "Entrance",
  "SelectTrial",
  "SelectPet",
  "AffirmPet"
}

function StateInstBase:CloseAllFlowPanels()
  local BindModule = self:GetBindModule()
  if not BindModule then
    return
  end
  for _, PanelName in ipairs(FlowPanelNames) do
    if BindModule:HasPanel(PanelName) then
      BindModule:ClosePanel(PanelName)
    end
  end
end

function StateInstBase:SetOtherCharacterHide(bHide)
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if UE.UObject.IsValid(Player.viewObj) then
    Player.viewObj:SetHiddenMask(bHide, UE.EPlayerForceHiddenType.Default)
  end
  local NPCs = _G.NRCModeManager:DoCmd(NPCModuleCmd.GetAllNPC)
  for _, NPC in pairs(NPCs) do
    NPC:SetVisibleForLegendaryBattleReason(not bHide)
  end
  self:DebugLog("SetOtherCharacterHide:", tostring(bHide))
end

function StateInstBase:DebugLog(Msg)
  Log.DebugFormat([[
[RogueStateLog]    State:%s    Phase:%s
Msg:     %s]], table.getKeyName(RogueModuleEnum.RogueStateEnum, self.State), table.getKeyName(StatePhase, self.StatePhase), Msg)
end

function StateInstBase:WarningLog(Msg)
  Log.WarningFormat([[
[RogueStateLog] Waring!    State:%s    Phase:%s
Msg:     %s]], table.getKeyName(RogueModuleEnum.RogueStateEnum, self.State), table.getKeyName(StatePhase, self.StatePhase), Msg)
end

function StateInstBase:ErrorLog(Msg)
  Log.ErrorFormat([[
[RogueStateLog] Error!    State:%s    Phase:%s
Msg:     %s]], table.getKeyName(RogueModuleEnum.RogueStateEnum, self.State), table.getKeyName(StatePhase, self.StatePhase), Msg)
end

return StateInstBase
