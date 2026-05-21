local HiddenActionRegistry = require("NewRoco.Modules.Core.Scene.Component.Hidden.HiddenActionRegistry")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local Delegate = require("Utils.Delegate")
local HiddenEvent = require("NewRoco.Modules.Core.Scene.Component.Hidden.HiddenEvent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local HiddenComponent = Base:Extend("HiddenComponent")
HiddenComponent.State = {
  Idle = 1,
  PendingStart = 2,
  Hidden = 3,
  PendingEnd = 4
}
HiddenComponent.InteractionLock = {Cue = 1, Net = 2}
HiddenComponent.InteractionLock_All = (function()
  local all_flags = 0
  for _, v in pairs(HiddenComponent.InteractionLock) do
    all_flags = all_flags | v
  end
  return all_flags
end)()

function HiddenComponent:Ctor()
  self.hiddenType = nil
  self.action = nil
  self.state = HiddenComponent.State.Idle
  self.initState = nil
  self.enteringDelegates = Delegate()
  self.endingDelegates = Delegate()
  self.cachedVisibility = nil
  self.nextTickRefreshState = false
  self.bannedEnvLabel = nil
  self.playerContext = {}
  MakeWeakTable(self.playerContext)
  self.interactionMutex = 0
  self.previousInteractionEnable = false
end

local TypeNone = Enum.WorldHide.WH_NONE

function HiddenComponent:Attach(owner)
  Base.Attach(self, owner)
  self.hiddenType, self.hiddenParam = self:GetConfigurationHiddenType()
  local petbase_conf = self.owner:GetConfPetData()
  if petbase_conf then
    self.bannedEnvLabel = petbase_conf.forbid_hide_envtagtype
  end
  if self.hiddenType == TypeNone then
    Log.Warning("[HiddenComponent] Attached to a NPC with no world_hide config", owner.config.id, owner.config.name)
    return
  end
  local bInitState = false
  local ref_conf = _G.DataConfigManager:GetNpcRefreshContentConf(self.owner.serverData.npc_base.npc_content_cfg_id, true)
  if ref_conf and ref_conf.npc_initial_status == Enum.NpcInitialStatus.NIS_MIMIC then
    if self.owner.BornDieComponent then
      self.owner.BornDieComponent.bEnablePerform = false
    end
    self:SetInitState(HiddenComponent.State.Hidden)
    Log.DebugFormat("Initial Hidden actor:%s, reason:%s", self.owner.config.name, "InitialState")
    bInitState = true
  end
  if not bInitState then
    local logicStatus = self:GetLogicStatus()
    local rst = self.owner:IsLogicStatus(logicStatus)
    if rst then
      self:SetInitState(HiddenComponent.State.Hidden)
      Log.DebugFormat("Initial Hidden actor:%s%u, reason:%s", self.owner.config.name, self.owner:GetServerId(), "LogistStatus")
    end
  end
  self.action = HiddenActionRegistry.Get(self.hiddenType, self.hiddenParam)
  if self.action then
    self.action:Init(self)
  end
  SceneUtils.RegisterNPCVisibilityNotify(self, true)
end

local Dummy = {}

function HiddenComponent:GetConfigurationHiddenType()
  local configHiddenType = TypeNone
  if not self.owner then
    return configHiddenType, Dummy
  end
  local mutType = self.owner.serverData.npc_base.mutation_type
  if PetMutationUtils.GetMutationValue(mutType, _G.Enum.MutationDiffType.MDT_SHINING) then
    local mutHiddenType = self.owner.config.shining_world_hide
    local mutHiddenParam = self.owner.config.shining_world_hide_param
    if mutHiddenType and mutHiddenType ~= TypeNone then
      return mutHiddenType, mutHiddenParam
    end
  end
  local RefreshContent = _G.DataConfigManager:GetNpcRefreshContentConf(self.owner.serverData.npc_base.npc_content_cfg_id, true)
  if RefreshContent then
    configHiddenType = RefreshContent.world_hide or TypeNone
    if configHiddenType ~= TypeNone then
      return configHiddenType, RefreshContent.world_hide_param
    end
  end
  configHiddenType = self.owner.config.world_hide or TypeNone
  if configHiddenType ~= TypeNone then
    return configHiddenType, self.owner.config.world_hide_param
  end
  if self.owner.config.traverse_data_type == Enum.Traverse_Data_Type.TDT_PETBASE then
    local petbase_conf = _G.DataConfigManager:GetPetbaseConf(self.owner.config.traverse_data_param[1], true)
    if petbase_conf then
      configHiddenType = petbase_conf.world_hide
      if configHiddenType ~= TypeNone then
        return configHiddenType, petbase_conf.world_hide_param
      end
    end
  end
  return configHiddenType, Dummy
end

function HiddenComponent:DeAttach()
  SceneUtils.UnregisterNPCVisibilityNotify(self)
  self.removed = true
  self.enteringDelegates:Invoke(AIDefines.ActionResult.Failed, self)
  self.enteringDelegates:Clear()
  self.endingDelegates:Invoke(AIDefines.ActionResult.Failed, self)
  self.endingDelegates:Clear()
  if self.action then
    self:ResetHide(true, true)
    self.action:Release()
    self.action = nil
  end
end

function HiddenComponent:UpdateData(ServerData, isReconnect)
  if isReconnect then
    local isServerAI = ServerData.npc_base and ServerData.npc_base.is_server_ai
    if not isServerAI then
      self:UpdateLogicStatus()
    else
      local logicStatus = self:GetLogicStatus()
      local rst = self.owner:IsLogicStatus(logicStatus)
      if self.state == HiddenComponent.State.Hidden or self.state == HiddenComponent.State.Idle then
        if rst then
          self:SetHide()
        else
          self:ResetHide()
        end
      end
    end
    self:ReturnInteractionMutex()
  end
end

function HiddenComponent:OnDisConnect()
  self:ReturnInteractionMutex()
end

function HiddenComponent:OnVisible()
  if not self.action then
    return
  end
  if not self.initState then
    return
  end
  if self.initState == HiddenComponent.State.Idle then
  elseif self.initState == HiddenComponent.State.Hidden then
    self.state = self.initState
    self.nextTickRefreshState = true
  end
  if self.state == HiddenComponent.State.Hidden then
    self.action:OnInitialHide()
    self:SetHide()
    self:UpdateLogicStatus()
  end
  self.initState = nil
end

function HiddenComponent:OnInvisible()
end

function HiddenComponent:OnDistanceOptimize(distance, viewDotValue, bulkyVisible, distanceRatio)
  if self.nextTickRefreshState then
    if self.initState == HiddenComponent.State.Hidden then
      self:SetHide()
      self:UpdateLogicStatus()
    end
    self.nextTickRefreshState = false
  end
  if self.owner.bulkyVisible ~= self.cachedVisibility then
    self:OnVisibilityChange(self.owner.bulkyVisible)
    self.cachedVisibility = self.owner.bulkyVisible
  end
end

function HiddenComponent:OnVisibilityChange(visible)
  if self:CanHide() and self.action then
    self.action:OnVisibilityChange(visible)
  end
end

function HiddenComponent:SetInitState(initState)
  self.initState = initState
end

local TraceStateChanging = false

function HiddenComponent:SetHidState(newState)
  local changed = newState ~= self.state
  if TraceStateChanging then
    Log.WarningFunc(function()
      return string.format("HidCmp State %d -> %d : %s", self.state, newState, self.owner.config.name)
    end)
  end
  self.state = newState
  return changed
end

function HiddenComponent:BeginHide()
  if not self.action or not self.owner.viewObj then
    return false
  end
  if not self:CheckLandLabel() then
    return false
  end
  self:PinToGround(self:IsMimicType())
  if self.state == HiddenComponent.State.PendingStart or self.state == HiddenComponent.State.Hidden then
    self.action:AssureHidden()
    return true
  end
  if self.state == HiddenComponent.State.Idle then
    self:BorrowInteractionMutex(HiddenComponent.InteractionLock.Cue)
    self:SetHidState(HiddenComponent.State.PendingStart)
    self.action:OnHidden()
    return true
  end
  return false
end

function HiddenComponent:EndHide(caller, callback)
  callback = callback or function()
  end
  if not self.action or not self.owner.viewObj then
    callback(caller, AIDefines.ActionResult.Invalid, self)
    return
  end
  if self.state == HiddenComponent.State.Idle then
    self.action:AssureUnhidden()
    callback(caller, AIDefines.ActionResult.Success, self)
    return
  end
  if self.state == HiddenComponent.State.PendingStart then
    Log.Warning("\230\173\163\229\156\168\229\140\191\232\184\170\228\184\173")
    callback(caller, AIDefines.ActionResult.Failed, self)
    return
  end
  self.endingDelegates:Add(caller, callback)
  if self.state == HiddenComponent.State.Hidden then
    self:BorrowInteractionMutex(HiddenComponent.InteractionLock.Cue)
    self:SetHidState(HiddenComponent.State.PendingEnd)
    self.action:OnUnhidden()
    return
  end
  if self.state == HiddenComponent.State.PendingEnd then
    self.action:AssureUnhidden()
    return
  end
end

function HiddenComponent:SetHide()
  if not self.action or not self.owner.viewObj then
    return
  end
  if not self:CheckLandLabel() then
    return
  end
  self:PinToGround(true)
  if self.state == HiddenComponent.State.PendingStart then
    self.action:AssureHidden()
    return
  end
  if self:SetHidState(HiddenComponent.State.Hidden) then
    self:UpdateLogicStatus()
  end
  self.action:AssureHidden(true)
end

function HiddenComponent:ResetHide(force, remove)
  if not self.action or not self.owner.viewObj then
    return
  end
  if not remove then
    self:UnpinToGround(true)
  end
  if self.state == HiddenComponent.State.PendingEnd then
    self.action:AssureUnhidden(force or false, remove)
    return
  end
  if self:SetHidState(HiddenComponent.State.Idle) then
    self:UpdateLogicStatus()
  end
  self.action:AssureUnhidden(true, remove)
end

function HiddenComponent:EnterHidden(result)
  if self.state == HiddenComponent.State.Idle then
    self:ReturnInteractionMutex(HiddenComponent.InteractionLock.Cue)
    self.action:AssureUnhidden(true)
    return
  end
  if self.state == HiddenComponent.State.PendingEnd then
    return
  end
  if self.state == HiddenComponent.State.Hidden then
    self:ReturnInteractionMutex(HiddenComponent.InteractionLock.Cue)
    return
  end
  self:ReturnInteractionMutex(HiddenComponent.InteractionLock.Cue)
  if AIDefines.ActionResult.Ok(result) then
    if self:SetHidState(HiddenComponent.State.Hidden) then
      self:UpdateLogicStatus()
    end
  else
    self:SetHidState(HiddenComponent.State.Idle)
  end
  self.owner:ScheduleNextTick(0)
  self.enteringDelegates:Invoke(result, self)
  self.enteringDelegates:Clear()
  self.owner:SendEvent(HiddenEvent.Hidden)
end

function HiddenComponent:FinalizeHidden(result, silent)
  if self.state == HiddenComponent.State.Hidden then
    self:ReturnInteractionMutex(HiddenComponent.InteractionLock.Cue)
    return
  end
  if self.state == HiddenComponent.State.PendingStart then
    return
  end
  self:UnpinToGround(false)
  if self.state == HiddenComponent.State.Idle then
  end
  self:ReturnInteractionMutex(HiddenComponent.InteractionLock.Cue)
  if AIDefines.ActionResult.Ok(result) then
    if self:SetHidState(HiddenComponent.State.Idle) then
      self:UpdateLogicStatus()
    end
  else
    if not silent then
      Log.Warning("HiddenComponent \233\128\128\229\135\186\233\154\144\229\140\191\229\164\177\232\180\165\239\188\140\229\183\178\230\129\162\229\164\141\229\142\159\230\157\165\231\154\132\230\160\183\229\173\144")
    end
    self:SetHidState(HiddenComponent.State.Hidden)
  end
  self.owner:ScheduleNextTick(0)
  self.endingDelegates:Invoke(result, self)
  self.endingDelegates:Clear()
  self.owner:SendEvent(HiddenEvent.UnHidden)
end

function HiddenComponent:UpdateLogicStatus()
  local AIComp = self.owner and self.owner.AIComponent
  if AIComp and AIComp.isServerAI then
    return
  end
  if self.removed then
    return
  end
  if AIComp and AIComp.IsCurrentInHome() then
    return
  end
  local status = self:GetLogicStatus()
  if not self.owner:IsLocal() and status then
    local hasStatus = self.owner.LogicStatusComponent:GetStatus(status)
    local isHidden = self:IsHidden()
    if hasStatus == isHidden then
      return
    end
    local req = _G.ProtoMessage.newZoneSceneAIModifyLogicStatusReq()
    req.npc_obj_id = self.owner.serverData.base.actor_id
    local op = _G.ProtoMessage.newLogicStatusOpInfo()
    op.op_type = self:IsHidden() and ProtoEnum.LogicStatusOpType.LSOT_ADD or ProtoEnum.LogicStatusOpType.LSOT_REMOVE
    op.status = status
    table.insert(req.operation, op)
    self:BorrowInteractionMutex(HiddenComponent.InteractionLock.Net)
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_A_I_MODIFY_LOGIC_STATUS_REQ, req, self, self.UpdateLogicStatusRsp, false, true)
  end
end

function HiddenComponent:UpdateLogicStatusRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Debug("UpdateLogicStatusRsp May Failed", rsp.ret_info.ret_code)
  end
  self:ReturnInteractionMutex(HiddenComponent.InteractionLock.Net)
  if self.owner and self.owner.PetHUDComponent then
    self.owner.PetHUDComponent:UpdateNPCNameColor()
  end
end

function HiddenComponent:BorrowInteractionMutex(mutex)
  mutex = mutex or HiddenComponent.InteractionLock_All
  local previousLocked = self.interactionMutex > 0
  if self.interactionMutex | mutex ~= self.interactionMutex then
    self.interactionMutex = self.interactionMutex | mutex
    if not previousLocked and self.interactionMutex > 0 then
      self:SetCanInteract(false)
    end
  end
end

function HiddenComponent:ReturnInteractionMutex(mutex)
  mutex = mutex or HiddenComponent.InteractionLock_All
  local previousLocked = self.interactionMutex > 0
  if self.interactionMutex & ~mutex ~= self.interactionMutex then
    self.interactionMutex = self.interactionMutex & ~mutex
    if previousLocked and 0 == self.interactionMutex then
      self:SetCanInteract(true)
    end
  end
end

function HiddenComponent:SetCanInteract(enable)
  if not self.owner.InteractionComponent then
    return
  end
  if enable then
    self.owner.InteractionComponent:SetInteractionEnable(true, NPCModuleEnum.NpcInteractDisableFlag.HIDDEN_COMP)
  else
    self.owner.InteractionComponent:SetInteractionEnable(false, NPCModuleEnum.NpcInteractDisableFlag.HIDDEN_COMP)
  end
end

HiddenComponent.Map_HideType2LogicStatus = nil

function HiddenComponent:GetLogicStatus()
  if HiddenComponent.Map_HideType2LogicStatus == nil then
    HiddenComponent.Map_HideType2LogicStatus = {
      [Enum.WorldHide.WH_DRILL] = Enum.SpaceActorLogicStatus.SALS_DRILL,
      [Enum.WorldHide.WH_MIMIC] = Enum.SpaceActorLogicStatus.SALS_MIMIC,
      [Enum.WorldHide.WH_STATIC] = Enum.SpaceActorLogicStatus.SALS_STATIC,
      [Enum.WorldHide.WH_HIDE] = Enum.SpaceActorLogicStatus.SALS_HIDE,
      [Enum.WorldHide.WH_MIMIC_OPTION] = Enum.SpaceActorLogicStatus.SALS_MIMIC_OPTION,
      [Enum.WorldHide.WH_GHOST] = Enum.SpaceActorLogicStatus.SALS_GHOST,
      [Enum.WorldHide.WH_THUNDER] = Enum.SpaceActorLogicStatus.SALS_THUNDER,
      [Enum.WorldHide.WH_DIVING] = Enum.SpaceActorLogicStatus.SALS_DIVING,
      [Enum.WorldHide.WH_FISHJUMP] = Enum.SpaceActorLogicStatus.SALS_FISHJUMP,
      [Enum.WorldHide.WH_TRAIL] = Enum.SpaceActorLogicStatus.SALS_TRAIL,
      [Enum.WorldHide.WH_FALLING] = Enum.SpaceActorLogicStatus.SALS_FALLING,
      [Enum.WorldHide.WH_DRILL_IMME] = Enum.SpaceActorLogicStatus.SALS_DRILL_IMME
    }
  end
  if self:CanHide() then
    return HiddenComponent.Map_HideType2LogicStatus[self.hiddenType]
  end
  return nil
end

function HiddenComponent:RegisterEnteringDelegate(caller, callback)
  if self.state == HiddenComponent.State.Idle or self.state == HiddenComponent.State.PendingStart then
    self.enteringDelegates:Add(caller, callback)
  elseif self.state == HiddenComponent.State.Hidden then
    callback(caller, AIDefines.ActionResult.Success, self)
  else
    callback(caller, AIDefines.ActionResult.Rejected, self)
  end
end

function HiddenComponent:RegisterEndingDelegate(caller, callback)
  if self.state == HiddenComponent.State.Hidden or self.state == HiddenComponent.State.PendingEnd then
    self.endingDelegates:Add(caller, callback)
  elseif self.state == HiddenComponent.State.Idle then
    callback(caller, AIDefines.ActionResult.Success, self)
  else
    callback(caller, AIDefines.ActionResult.Rejected, self)
  end
end

function HiddenComponent:CanHide()
  return self.hiddenType and self.hiddenType ~= Enum.WorldHide.WH_NONE
end

function HiddenComponent:CheckLandLabel()
  local currentLabels = self.owner:GetCurrentEnvLabel()
  for _, label in ipairs(currentLabels) do
    if table.contains(self.bannedEnvLabel, label) then
      return false
    end
  end
  return true
end

function HiddenComponent:IsHidden()
  return self.state ~= HiddenComponent.State.Idle
end

function HiddenComponent:GetHiddenType()
  return self.hiddenType
end

function HiddenComponent:IsMimicType()
  return self.hiddenType == Enum.WorldHide.WH_MIMIC_OPTION or self.hiddenType == Enum.WorldHide.WH_MIMIC
end

function HiddenComponent:IsDrillType()
  return self.hiddenType == Enum.WorldHide.WH_DRILL or self.hiddenType == Enum.WorldHide.WH_DRILL_IMME
end

function HiddenComponent:GetMimicObject()
  if self:IsMimicType() then
    local mimic_action = self.action
    return mimic_action.spawnedMimicTarget
  end
  return nil
end

function HiddenComponent:SetPlayerContext(playerBase)
  self.playerContext[1] = playerBase
end

function HiddenComponent:GetPlayerContext()
  return self.playerContext[1]
end

local TraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel5)
local debugColor_1 = UE4.FLinearColor(0, 1, 1, 1)
local debugColor_2 = UE4.FLinearColor(1, 0, 1, 1)

function HiddenComponent:PinToGround(imme)
  if not self.action or not self.action:EnablePinToGround() then
    return
  end
  local SkillComp = self.owner.WorldCombatSkillComponent
  local bIsPlayingSkill = SkillComp and SkillComp.currentContext ~= nil
  if bIsPlayingSkill then
    Log.Debug("HiddenComponent:PinToGround Blocked!", self.owner:GetServerId())
    return
  end
  local view = self.owner.viewObj
  local moveComp = view and view.GetMovementComponent and view:GetMovementComponent() or nil
  if not moveComp then
    return
  end
  local floor = moveComp.CurrentFloor
  local isMimicType = self:IsMimicType()
  local normal
  if not isMimicType and floor and floor.HitResult.ImpactNormal.Z > 0 then
    normal = floor.HitResult.ImpactNormal
  else
    local TraceBegin = self.owner:GetActorLocation()
    local TraceEnd = TraceBegin - UE.FVector(0, 0, 500)
    TraceBegin = TraceBegin + UE.FVector(0, 0, 200)
    local ignoreActors
    if isMimicType and self.action.spawnedMimicTarget then
      ignoreActors = UE.TArray(UE.AActor)
      ignoreActors:Add(self.action.spawnedMimicTarget)
    end
    local debugType = _G.GlobalConfig.DebugLuaBTree and 2 or 0
    local Hit, Success = UE.UKismetSystemLibrary.Abs_LineTraceSingle(view, TraceBegin, TraceEnd, TraceChannel, false, ignoreActors, debugType, nil, true, debugColor_1, debugColor_2, 5)
    if Success then
      local lNormal = Hit.ImpactNormal
      normal = UE.FVector(lNormal.X, lNormal.Y, lNormal.Z)
    else
      return
    end
  end
  local actorFwd = self.owner:GetForwardVector()
  local actorLft = normal:Cross(actorFwd)
  local actorRot = UE.UKismetMathLibrary.MakeRotFromYZ(actorLft, normal)
  moveComp.OnlyUseYawRotation = false
  if imme then
    self.owner:SetActorRotation(actorRot)
  else
    view:SetBpRotateRate(UE.FRotator(360, 360, 360))
    view:LerpToRotation(actorRot)
  end
end

function HiddenComponent:UnpinToGround(imme)
  if not self.action:EnablePinToGround() then
    return
  end
  local SkillComp = self.owner.WorldCombatSkillComponent
  local bIsPlayingSkill = SkillComp and SkillComp.currentContext ~= nil
  if bIsPlayingSkill then
    Log.Debug("HiddenComponent:UnpinToGround Blocked!", self.owner:GetServerId())
    return
  end
  local view = self.owner.viewObj
  local moveComp = view and view:GetMovementComponent() or nil
  if not moveComp then
    return
  end
  local curRot = self.owner:GetActorRotation()
  curRot.Pitch = 0
  curRot.Roll = 0
  moveComp.OnlyUseYawRotation = true
  if imme then
    self.owner:SetActorRotation(curRot)
  else
    view:SetBpRotateRate(UE.FRotator(360, 360, 360))
    view:LerpToRotation(curRot)
  end
end

local HIDDEN_REASON = 4

function HiddenComponent:SubItemVisibility()
  return 0 == self.owner.hiddenFlag & ~(1 << HIDDEN_REASON)
end

function HiddenComponent:SetVisible(flag)
  local ownerVisibility = self.owner.hiddenFlag > 0
  local subItemVisibility = self:SubItemVisibility()
  if self.action and (self:IsMimicType() or self:IsDrillType()) then
    self.action:SetVisible(subItemVisibility, ownerVisibility)
  end
end

function HiddenComponent:EnterBattle()
  if self:IsHidden() and self.action then
    self.action:EnterBattle()
  end
end

function HiddenComponent:LeaveBattle()
  if self:IsHidden() and self.action then
    self.action:LeaveBattle()
  end
end

function HiddenComponent:GetState()
  return self.state
end

local RESIST_CAPTURE_LIST

local function GetResistCaptureList()
  if nil == RESIST_CAPTURE_LIST then
    RESIST_CAPTURE_LIST = {}
    local ban_catch_pet_world_hide_type = _G.DataConfigManager:GetNpcGlobalConfig("ban_catch_pet_world_hide_type", true)
    if ban_catch_pet_world_hide_type and ban_catch_pet_world_hide_type.str then
      local WHEnumNames = string.split(ban_catch_pet_world_hide_type.str, ";")
      for _, WHEnumName in ipairs(WHEnumNames) do
        local resistCapture = Enum.WorldHide[WHEnumName]
        if resistCapture then
          RESIST_CAPTURE_LIST[resistCapture] = true
        end
      end
    else
      RESIST_CAPTURE_LIST[Enum.WorldHide.WH_MIMIC] = true
      RESIST_CAPTURE_LIST[Enum.WorldHide.WH_MIMIC_OPTION] = true
      RESIST_CAPTURE_LIST[Enum.WorldHide.WH_GHOST] = true
      RESIST_CAPTURE_LIST[Enum.WorldHide.WH_DIVING] = true
      RESIST_CAPTURE_LIST[Enum.WorldHide.WH_DRILL_IMME] = true
    end
  end
  return RESIST_CAPTURE_LIST
end

function HiddenComponent:IsResistCapture(ballActId)
  if not self:CanHide() then
    return false
  end
  if not self:IsHidden() then
    return false
  end
  if not GetResistCaptureList()[self.hiddenType] then
    return false
  end
  local ballActConf = ballActId and _G.DataConfigManager:GetBallAct(ballActId, true)
  if ballActConf and table.contains(ballActConf.ball_wh_mimic, self.hiddenType) then
    return false
  end
  return true
end

return HiddenComponent
