local Class = _G.MakeSimpleClass
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local NPCModuleCmd = require("NewRoco.Modules.Core.NPC.NPCModuleCmd")
local ActionUtils = require("NewRoco.Modules.Core.NPC.Actions.ActionUtils")
local NPCActionEvent = require("NewRoco.Modules.Core.NPC.Actions.NPCActionEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local NpcOptionEvent = require("NewRoco.Modules.Core.NPC.Executors.NpcOptionEvent")
local EventDispatcher = require("Common.EventDispatcher")
local NavigationComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.NavigationComponent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local UIUtils = require("NewRoco.Utils.UIUtils")
local Base = require("NewRoco.Modules.Core.NPC.Actions.CommonActionBase")
local ProtoEnum = require("Data.PB.ProtoEnum")
local MinExecuteInterval = 0.3
local VisualDebug = false
local NPCActionBase = Base:Extend("NPCActionBase")

function NPCActionBase.PostInit(Option, Action, Info, OwnerNpc)
end

function NPCActionBase:PreCtor()
  Base.PreCtor(self)
  self.SkipSubmit = false
  self.SkipCommit = false
  self.NeedModal = false
  self.bInteracting = false
  self.LastExecuteTime = -1
  self.playerId = nil
  self.shouldSync = false
  self.DoAction = false
  self.DisableInterval = false
end

function NPCActionBase:Ctor(Owner, Config, Info, View)
  Base.Ctor(self, Owner, Config)
  self.Info = Info
  if self.Owner then
    self.OwnerNpc = self.Owner.owner
  else
    self.OwnerNpc = View
  end
end

function NPCActionBase:NeedsValidation()
  return false
end

function NPCActionBase:GetCreatorID()
  if not self.OwnerNpc then
    return 0
  end
  return self.OwnerNpc:GetCreatorID()
end

function NPCActionBase:GetOwnerActorLocation()
  if not self.OwnerNpc then
    return FVectorZero
  end
  local OwnerNPC = self.OwnerNpc
  if OwnerNPC.viewObj then
    return OwnerNPC:GetActorLocation()
  else
    local Point = OwnerNPC.serverData.base.born_pt.pos
    return UE4.FVector(Point.x, Point.y, Point.z)
  end
end

function NPCActionBase:UpdateInfo(Info, Reconnect, InteractingAvatarID)
  self.Info = Info
end

function NPCActionBase:GetValidationInfo()
  return true, 0, 0
end

function NPCActionBase:Execute(playerId, needSendReq)
  if self.Owner then
    self.Owner:IncreaseExecuteTimes()
  end
  self.needSendReq = needSendReq
  if self.needSendReq == nil then
    self.needSendReq = true
  end
  self.isFinished = false
  self.playerId = playerId
  self:Log("Execute", needSendReq)
  if VisualDebug and self.OwnerNpc and self.Owner then
    local World = _G.UE4Helper.GetCurrentWorld()
    local Owner = self:GetOwnerNPCView()
    local Color = UE.FLinearColor(0, 1, 0, 1)
    local ColorRed = UE.FLinearColor(1, 0, 0, 1)
    local Location = Owner:K2_GetActorLocation()
    local Player = self:GetPlayer()
    local PlayerLocation = Player.viewObj:K2_GetActorLocation()
    local Dist2D = PlayerLocation:Dist2D(Location)
    local Text = string.format([[
%s
%d=%s]], self.OwnerNpc:DebugNPCNameAndID(), self.Owner.config.id, table.getKeyName(Enum.ActionType, self.Config.action_type))
    UE.UKismetSystemLibrary.DrawDebugString(World, Location, Text, nil, ColorRed, 999)
    UE.UKismetSystemLibrary.DrawDebugSphere(World, Location, Dist2D, 24, Color, 999, 2)
    Log.ErrorFormat("ExecuteAction!NPC=%s,Option=%d,Action=%s", self.OwnerNpc:DebugNPCNameAndID(), self.Owner.config.id, table.getKeyName(Enum.ActionType, self.Config.action_type))
  end
  self:RegisterThisActionToPlayer()
  self.LastExecuteTime = _G.UpdateManager.Timestamp
  _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.NpcActionExecute, self)
  self:BeforeSubmit()
  self:Submit()
end

function NPCActionBase:Finish(success, data, param)
  self:Log("Finish", success, data, param)
  self.isFinished = true
  if nil == success then
    self.bIsSuccess = true
  else
    self.bIsSuccess = true == success
  end
  self.LastExecuteTime = _G.UpdateManager.Timestamp
  self:Commit(data, param)
end

function NPCActionBase:GetIsFirst()
  return true
end

function NPCActionBase:Submit()
  if self.SkipSubmit then
    return
  end
  if not self.Owner and not self.OwnerNpc then
    self:LogError("NPCActionBase:Submit\231\154\132\230\151\182\229\128\153Owner\230\136\150\232\128\133OwnerNpc\228\184\141\229\173\152\229\156\168\239\188\129")
  end
  if self.OwnerNpc and self.OwnerNpc.Watch then
    self:LogError("Submitting Action")
  end
  self:Log("Submit")
  if self.needSendReq and self.Owner and self.OwnerNpc then
    local req = ProtoMessage:newZoneSceneNpcNextActReq()
    req.option_id = self.Owner.config.id
    req.npc_id = self.OwnerNpc.serverData.base.actor_id
    req.first_act = self:GetIsFirst()
    req.battle_radius = BattleConst.Define.BattleFieldRange
    self:FillRequest(req)
    if self.OwnerNpc.simulate then
      NRCModeManager:DoCmd(PGCModuleCmd.SimulateServerNextAction, req, self, self.CheckOnSubmit)
    else
      _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NPC_NEXT_ACT_REQ, req, self, self.CheckOnSubmit, self.NeedModal, true, nil, self.FailedOnSubmit)
    end
  else
    local rsp = _G.ProtoMessage:newZoneSceneNpcNextActRsp()
    rsp.ret_info.ret_code = 0
    self:CheckOnSubmit(rsp)
  end
end

function NPCActionBase:FailedOnSubmit(CmdID, Msg)
  if CmdID ~= ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NPC_NEXT_ACT_REQ then
    return
  end
  local rsp = _G.ProtoMessage:newZoneSceneNpcNextActRsp()
  rsp.ret_info.ret_code = ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_CLINET_ACTION_BATTLE_ERROR
  self:CheckOnSubmit(rsp)
end

function NPCActionBase:FillRequest(req)
  if self.Owner and self.Owner.owner then
    req.npc_pt = self.Owner.owner:GetServerPoint()
  end
  local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    req.avatar_pt = localPlayer:GetServerPoint()
    local PlayerView = localPlayer.viewObj
    local RideComp = PlayerView and PlayerView.BP_RideComponent
    local Pet = RideComp and RideComp.ScenePet
    if Pet then
      req.ride_id = Pet.gid
    end
  end
  req.data1 = _G.BattleConst.Define.BattleFieldRange
end

function NPCActionBase:CheckOnSubmit(rsp)
  local Conf = _G.DataConfigManager:GetNpcActionConf(self.Config.action_type, true)
  if Conf then
    if Conf.wait_begin_data then
      if self:IsReadyToBeginAction() then
        self:OnSubmit(rsp)
      else
        self.SubMitRsp = rsp
        self.Owner:AddEventListener(self, NpcOptionEvent.NotifyBeginActionParams, self.NotifyBeginActionParams)
      end
    else
      self:OnSubmit(rsp)
    end
  else
    self:OnSubmit(rsp)
  end
end

function NPCActionBase:OnSubmit(rsp)
  self:Log("OnSubmit")
  local ErrorCode = rsp.ret_info.ret_code
  if 0 ~= ErrorCode then
    if table.contains(ActionUtils.ExpectedErrorCodes, ErrorCode) then
      self:ShowTips(ErrorCode)
    elseif self.OnSubmitErrorRetInfo and self:OnSubmitErrorRetInfo(rsp.ret_info, rsp) then
    else
      self:LogError("\229\143\145\233\128\129NextAct:OnSubmit,\229\155\158\229\140\133\231\130\184\229\149\166", _G.LuaText:GetErrorDesc(ErrorCode) or ErrorCode)
    end
    local player = self:GetPlayer()
    player:StopAnim("Walk", 0.25)
    self:RestIsSelectBtnBySubmitError(self.Config.action_type)
    self:TryShowTipsByErrorCode(ErrorCode)
  end
  if self.Owner then
    self.Owner:SetNeedStatusNotify(false)
  end
  self:SendEvent(NPCActionEvent.OnExecute, rsp)
end

function NPCActionBase:TryShowTipsByErrorCode(errorCode)
  if errorCode == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_FUNC_BANNED_TRANSFORM then
    local now = os.clock()
    if not self._lastTransformBannedTipsTime or now - self._lastTransformBannedTipsTime >= 2 then
      self._lastTransformBannedTipsTime = now
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.transform_ls_llegal)
    end
  end
end

function NPCActionBase:Commit(data, param)
  self:Log("Commit")
  if not self.SkipCommit and not self.Owner and not self.OwnerNpc then
    self:LogError("NPCActionBase:Commit\231\154\132\230\151\182\229\128\153Owner\230\136\150\232\128\133OwnerNpc\228\184\141\229\173\152\229\156\168\239\188\129")
  end
  if self.OwnerNpc and self.OwnerNpc.Watch then
    self:LogError("Commiting Action", table.getKeyName(Enum.ActionType, self.Config.action_type), self.className)
  end
  if self.needSendReq == nil then
    self.needSendReq = true
  end
  if self.needSendReq and self.OwnerNpc and self.Owner and not self.SkipCommit and DialogueUtils.IsClientCommit(self.Config.action_type) then
    local NextActReq = ProtoMessage:newZoneSceneNpcNextActReq()
    NextActReq.npc_id = self.OwnerNpc.serverData.base.actor_id
    NextActReq.option_id = self.Owner.optionInfo.option_id
    NextActReq.battle_radius = _G.BattleConst.Define.BattleFieldRange
    if data then
      NextActReq.data1 = data
    end
    if param then
      NextActReq.commit_cur_act_params = param
    end
    if self.DialogueConf then
      NextActReq.cur_dialog_id = self.DialogueConf.id
    end
    self.Owner.isWaitingForRsp = true
    self:FillCommit(NextActReq)
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NPC_NEXT_ACT_REQ, NextActReq, self, self.OnCommit, self.NeedModal, true, nil, self.FailedOnCommit)
  else
    local rsp = _G.ProtoMessage:newZoneSceneNpcNextActRsp()
    rsp.ret_info.ret_code = 0
    self:OnCommit(rsp)
  end
end

function NPCActionBase:FailedOnCommit(CmdID, Msg)
  if CmdID ~= ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NPC_NEXT_ACT_REQ then
    return
  end
  local rsp = _G.ProtoMessage:newZoneSceneNpcNextActRsp()
  rsp.ret_info.ret_code = ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_CLINET_ACTION_BATTLE_ERROR
  self:OnCommit(rsp)
end

function NPCActionBase:FillCommit(req)
  if self.Owner and self.Owner.owner then
    req.npc_pt = self.Owner.owner:GetServerPoint()
  end
  local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    req.avatar_pt = localPlayer:GetServerPoint()
    local PlayerView = localPlayer.viewObj
    local RideComp = PlayerView and PlayerView.BP_RideComponent
    local Pet = RideComp and RideComp.ScenePet
    if Pet then
      req.ride_id = Pet.gid
    end
  end
  req.data1 = _G.BattleConst.Define.BattleFieldRange
end

function NPCActionBase:OnCommit(rsp)
  self:Log("OnCommit")
  if self.Owner then
    self.Owner.isWaitingForRsp = false
  end
  local ErrorCode = rsp.ret_info.ret_code
  if 0 ~= ErrorCode then
    if table.contains(ActionUtils.ExpectedErrorCodes, ErrorCode) then
      self:ShowTips(ErrorCode)
    elseif self.OnCommitErrorRetInfo and self:OnCommitErrorRetInfo(rsp.ret_info, rsp) then
    else
      self:LogError("\229\143\145\233\128\129NextAct:OnCommit,\229\155\158\229\140\133\231\130\184\229\149\166", _G.LuaText:GetErrorDesc(ErrorCode) or ErrorCode)
    end
    local player = self:GetPlayer()
    player:StopAnim("Walk", 0.25)
  end
  self:SendEvent(NPCActionEvent.OnFinish, rsp, self.bIsSuccess)
  _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.NpcActionFinish, self)
  self:UnregisterThisActionToPlayer()
  self:PostOnCommit(rsp)
  self.bIsSuccess = nil
  self.player = nil
end

function NPCActionBase:SetInteracting(Interacting)
  if Interacting == self.bInteracting then
    return
  end
  self.bInteracting = Interacting
  self.Owner:OnPlayerEnterActionArea()
end

function NPCActionBase:OnDialogueAction()
  NRCEventCenter:DispatchEvent(NPCModuleEvent.NpcActionExecute, self)
end

function NPCActionBase:HasLocalPerform()
  return DialogueUtils.IsClientCommit(self.Config.action_type)
end

function NPCActionBase:FreezePlayer()
  local player = self:GetPlayer()
  if player then
    player:Stop()
  end
end

function NPCActionBase:DiffInfo(InfoA, InfoB)
  if InfoA == InfoB then
    return true
  end
  if InfoA and InfoB then
    local Same = InfoA.act_type == InfoB.act_type
    Same = Same and InfoA.bound_dialog_id == InfoB.bound_dialog_id
    Same = Same and InfoA.act_status == InfoB.act_status
    Same = Same and InfoA.btle_cfg_id == InfoB.btle_cfg_id
    Same = Same and InfoA.dialog_id == InfoB.dialog_id
    return Same
  else
    return false
  end
end

function NPCActionBase:GetOwnerNPC()
  return self.OwnerNpc
end

function NPCActionBase:GetOwnerNPCView()
  local NPC = self:GetOwnerNPC()
  return NPC and NPC.viewObj
end

function NPCActionBase:ShowTips(Code)
  if Code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_CATCH_FORBID then
    local owner = self:GetOwnerNPC()
    if owner then
      local serverData = owner.serverData
      if serverData then
        local tip, ownerName = UIUtils.GetHighValuePetTipsAndOwnerName(serverData)
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tip)
      end
    end
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText[string.format("Error_Code_%d", Code)])
  end
end

function NPCActionBase:SetViewObjOption()
  if not self.OwnerNpc then
    return
  end
  local viewObj = self.OwnerNpc.viewObj
  if viewObj and viewObj.SetOptionCfg then
    viewObj:SetOptionCfg(self.Owner.config)
  end
end

function NPCActionBase:DoCmd(...)
  return _G.NRCModeManager:DoCmd(...)
end

function NPCActionBase:Destroy()
  EventDispatcher.Detach(self)
end

function NPCActionBase:IsNeedCloseDialogueUI()
  return true
end

function NPCActionBase:RestIsSelectBtnBySubmitError(actionType)
  local panelName = "LobbyMain"
  local moduleName = "MainUIModule"
  local touchReasonType
  if actionType == ProtoEnum.ActionType.ACT_TRIG_MINIGAME then
    touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).MINIGAME
  elseif actionType == ProtoEnum.ActionType.ACT_DIALOG then
    touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).DIALOG
  elseif actionType == ProtoEnum.ActionType.ACT_OPEN_TEAM_BATTLE_UI then
    touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).TEAMBATTLE
  end
  if touchReasonType then
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, moduleName, panelName, touchReasonType)
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetLockOpenSubUI, false)
  end
end

function NPCActionBase:IsReadyToBeginAction()
  if not self.Owner then
    return true
  end
  local Params = self.Owner:GetBeginActionParams(self.Config.action_type)
  if Params then
    self:BeforeBeginAction(Params)
    return true
  else
    return false
  end
end

function NPCActionBase:NotifyBeginActionParams(Option, Action)
  if Option == self.Owner then
    local Params = self.Owner:GetBeginActionParams(self.Config.action_type)
    if Params then
      self:BeforeBeginAction(Params)
      if self.SubMitRsp then
        self:OnSubmit(self.SubMitRsp)
        self.SubMitRsp = nil
      end
    else
      self:LogError("amonsu:NPCActionBase:NotifyBeginActionParams \230\178\161\230\156\137\231\173\137\229\136\176\233\156\128\232\166\129\231\154\132\229\137\141\231\189\174\230\149\176\230\141\174!!!")
    end
    self.Owner:RemoveEventListener(self, NpcOptionEvent.NotifyBeginActionParams, self.NotifyBeginActionParams)
  end
end

function NPCActionBase:BeforeBeginAction(Action)
  if self.Owner then
    self.Owner:RemoveBeginActionParams(self.Config.action_type)
  end
end

function NPCActionBase:BeforeSubmit()
  local ActionType = self.Config.action_type
  local Conf = _G.DataConfigManager:GetNpcActionConf(ActionType, true)
  if not Conf then
    return
  end
  if not Conf.wait_begin_data then
    return
  end
  local Params = self.Owner:GetBeginActionParams(ActionType)
  if Params then
    self:BeforeBeginAction(Params)
  else
    self:LogWarning("amonsu:NPCActionBase:BeforeSubmit \230\178\161\230\156\137\230\139\191\229\136\176\233\156\128\232\166\129\231\154\132\229\137\141\231\189\174\230\149\176\230\141\174!!!")
  end
end

function NPCActionBase:PostOnCommit(rsp)
  if self and self.Owner then
    self.Owner:ClearRideRestoreState()
  end
end

function NPCActionBase:OnPlayerLeaveActionArea()
end

function NPCActionBase:IfActionNeedStatusNotify()
  if self.OwnerNpc.simulate then
    return false
  end
  return true
end

function NPCActionBase:CacheSyncInfo(npcInfo)
  self.npcSyncInfo = npcInfo
end

function NPCActionBase:GetOwnerConfig()
  if self.Owner and self.Owner.config then
    return self.Owner.config
  end
  if self.npcSyncInfo and self.npcSyncInfo.option_id then
    return _G.DataConfigManager:GetNpcOptionConf(self.npcSyncInfo.option_id)
  end
end

function NPCActionBase:SkipInDialogue()
  if not self.isFinished then
    self:OnSkipInDialogue()
  else
    self:LogWarning("NPCActionBase:SkipInDialogue  self.isFinished is true")
  end
end

function NPCActionBase:OnSkipInDialogue()
end

function NPCActionBase:CanSkipInDialogue()
  return false
end

function NPCActionBase:ExecuteWhenSkipping()
end

function NPCActionBase:ReLinkHand()
  local player = self:GetPlayer()
  if not player then
    return
  end
  player:ReLinkHand(PlayerModuleEvent.LinkReasonFlags.DIALOGUE)
end

function NPCActionBase:UnLinkHand()
  local player = self:GetPlayer()
  if not player then
    return
  end
  player:UnLinkHand(PlayerModuleEvent.LinkReasonFlags.DIALOGUE)
end

function NPCActionBase:SyncAction()
  local owner = self:GetOwnerNPC()
  if not owner then
    return
  end
  local option_conf = self:GetOwnerConfig()
  if not option_conf then
    return
  end
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local req = _G.ProtoMessage:newZoneClientOperationReq()
  local playerData = localPlayer and localPlayer.serverData
  local base = playerData and playerData.base
  local player_id = base and base.actor_id
  if not player_id then
    return
  end
  req.operation.operator_id = player_id
  req.operation.aim_info = nil
  req.operation.pet_action_info = nil
  req.operation.operator_type = 2
  req.operation.npc_action_info.operation_target_id = owner.serverData.base.actor_id
  req.operation.npc_action_info.option_id = option_conf.id
  req.operation.npc_action_info.operation_type = self.Config.action_type
  req.operation.npc_action_info.action_status = NPCModuleEnum.ActionStatus.Begin
  if self.Info then
    req.operation.npc_action_info.act_exec_success = self.Info.act_exec_success
  end
  local Position = localPlayer:GetActorLocation()
  req.operation.npc_action_info.operator_location.pos.x = math.floor(Position.X)
  req.operation.npc_action_info.operator_location.pos.y = math.floor(Position.Y)
  req.operation.npc_action_info.operator_location.pos.z = math.floor(Position.Z)
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req)
end

function NPCActionBase:Preload()
  self:OnPreload()
end

function NPCActionBase:OnPreload()
end

return NPCActionBase
