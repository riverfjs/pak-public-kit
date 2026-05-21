local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local SceneAnimEnum = require("NewRoco.Modules.Core.Scene.Common.SceneAnimEnum")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local OverlapAwareVisibilityComponent = require("NewRoco.Modules.Core.Scene.Component.Visibility.OverlapAwareVisibilityComponent")
local WeakSceneCharacter = require("NewRoco.Modules.Core.Scene.Common.WeakSceneCharacter")
local Base = ActorComponent
local SocketSnapComponent = Base:Extend("SocketSnapComponent")

function SocketSnapComponent:Ctor(forceInit)
  self.forceInit = forceInit or false
end

function SocketSnapComponent:Attach(owner)
  Base.Attach(self, owner)
  self.isPlayer = self.owner.uin ~= nil
  self.SnappedSocket = {}
  self.SnappingTargetWeak = nil
  self.SnappingTargetRef = nil
  self.SnappingSocket = nil
  self.SnappingTargetSocket = nil
  self.SnappingAnimation = nil
  self.SnappingSpeed = 0
  self.DeferApplyAttachmentList = nil
  self.RelativeTransform = UE.FTransform()
  if self.forceInit then
    self:UpdateData(self.owner.serverData, false)
  end
end

function SocketSnapComponent:DeAttach()
  if self.SnappingTargetWeak then
    self:CancelSnap()
  end
  self:RemoveCallback()
  self.DeferApplyAttachmentList = nil
end

function SocketSnapComponent:OnResourceLoaded()
  if self.SnappingTargetRef then
    self:ApplyAttachment()
  end
  if self.DeferApplyAttachmentList then
    for _, otherSnapComp in ipairs(self.DeferApplyAttachmentList) do
      otherSnapComp:ApplyAttachment()
    end
    self.DeferApplyAttachmentList = nil
  end
end

function SocketSnapComponent:RegisterDeferApplyAttachment(otherSnapComp)
  if not self.DeferApplyAttachmentList then
    self.DeferApplyAttachmentList = {}
  end
  if not table.contains(self.DeferApplyAttachmentList, otherSnapComp) then
    table.insert(self.DeferApplyAttachmentList, otherSnapComp)
  end
end

function SocketSnapComponent:UpdateData(ServerData, isReconnect)
  local isServerAi = ServerData.npc_base and ServerData.npc_base.is_server_ai
  if isServerAi then
    local AIInfo = ServerData.ai_info
    local AIMoveInfo = AIInfo and AIInfo.ai_move_info
    local stickInfo = AIMoveInfo and AIMoveInfo.stick_to_info
    if stickInfo then
      local target_actor_id = stickInfo.target_actor_id
      self:SetSnappingTargetByActorId(target_actor_id)
      self.SnappingSocket = stickInfo.self_socket
      self.SnappingTargetSocket = stickInfo.target_socket
      self:SetRelativeRotation(stickInfo.rotate.x, stickInfo.rotate.y, stickInfo.rotate.z)
    else
      self:SetSnappingTargetByActorId(nil)
    end
  end
  self:ApplyAttachment()
end

function SocketSnapComponent:SetSnappingTargetByActorId(actor_id, actor_hint)
  if self.SnappingTargetWeak then
    if self.SnappingTargetWeak == actor_id then
      return
    end
    self.SnappingTargetWeak:Release()
    self.SnappingTargetWeak = nil
  end
  self:ClearTargetView()
  if actor_id then
    self.SnappingTargetWeak = WeakSceneCharacter(actor_id, actor_hint):RegisterInBound(self, self.OnTargetInBound):RegisterOutBound(self, self.OnTargetOutBound)
    self.SnappingTargetWeak:FlushInBound()
  end
end

function SocketSnapComponent:OnTargetInBound(weakRef, character)
  if character then
    self:SetTargetView(character)
  else
    self:ClearTargetView()
  end
end

function SocketSnapComponent:OnTargetOutBound(weakRef)
  self:ClearTargetView()
end

function SocketSnapComponent:SetTargetView(newTarget)
  if self.SnappingTargetRef == newTarget then
    return
  end
  self:ClearTargetView()
  self.SnappingTargetRef = newTarget
  if newTarget then
    if newTarget.isLocal then
      NRCEventCenter:RegisterEvent("SocketSnapComponent", self, SceneEvent.OnPlayerDead, self.OnTargetTeleport)
      NRCEventCenter:RegisterEvent("SocketSnapComponent", self, SceneEvent.PlayerTeleportStart, self.OnTargetTeleport)
    end
    self:ApplyAttachment()
  end
end

function SocketSnapComponent:ClearTargetView()
  if not self.SnappingTargetRef then
    return
  end
  local oldTarget = self.SnappingTargetRef
  self.SnappingTargetRef = nil
  if oldTarget.isLocal then
    NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnPlayerDead, self.OnTargetTeleport)
    NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerTeleportStart, self.OnTargetTeleport)
    if self.owner then
      self.owner:EnsureComponent(OverlapAwareVisibilityComponent):CheckInBoundAndMarkHidden(true, true, false)
    end
  end
  self:ClearAttachment()
end

function SocketSnapComponent:OnTargetTeleport()
  self:CancelSnap()
end

function SocketSnapComponent:StickToSocketValid(Socket)
  local modelConf = self.owner.modelConf
  if modelConf then
    return table.contains(modelConf.enable_stick_to_socket, Socket)
  else
    return false
  end
end

local PlayerEnabledSitckedSocket

function SocketSnapComponent:StickedSocketValid(Socket)
  local modelConf = self.owner.modelConf
  if modelConf then
    return table.contains(modelConf.enable_sticked_socket, Socket)
  else
    if not PlayerEnabledSitckedSocket then
      PlayerEnabledSitckedSocket = {}
      local socket_list = _G.DataConfigManager:GetNpcGlobalConfig("sticked_socket_player", true).numList
      PlayerEnabledSitckedSocket = socket_list and table.pack(table.unpack(socket_list)) or {}
    end
    return table.contains(PlayerEnabledSitckedSocket, Socket)
  end
end

local StickSocketMapping

function SocketSnapComponent:GetStickSocketName(Socket)
  if not StickSocketMapping then
    local str_list = _G.DataConfigManager:GetNpcGlobalConfig("stick_to_socket_enum_mapping", true).str
    StickSocketMapping = str_list and string.split(str_list, ";") or {}
  end
  return StickSocketMapping[Socket + 1]
end

function SocketSnapComponent:SnapTo(TargetCharacter, SelfSocket, TargetSocket, Speed, Animation, skipCheck)
  if self.isPlayer then
    return false
  end
  if not TargetCharacter or TargetCharacter.isDestroy then
    Log.Debug("SocketSnapComponent:SnapTo TargetCharacter is nil or isDestroy")
    return false
  end
  if not skipCheck and not self:StickToSocketValid(SelfSocket) then
    Log.Debug("SocketSnapComponent:SnapTo SelfSocket is not valid")
    return false
  end
  local targetSnapComp = TargetCharacter:EnsureComponent(SocketSnapComponent)
  if not skipCheck and not targetSnapComp:StickedSocketValid(TargetSocket) then
    Log.Debug("SocketSnapComponent:SnapTo TargetSocket is not valid")
    return false
  end
  if not skipCheck and table.contains(targetSnapComp.SnappedSocket, TargetSocket) then
    Log.Debug("SocketSnapComponent:SnapTo TargetSocket is already snapped")
    return false
  end
  table.insert(targetSnapComp.SnappedSocket, TargetSocket)
  self.SnappingSocket = SelfSocket
  self.SnappingTargetSocket = TargetSocket
  self.SnappingAnimation = Animation and SceneAnimEnum.AnimationNameRev[Animation] or nil
  self.SnappingSpeed = (Speed or 0) * 0.01
  local target_actor_id = TargetCharacter:GetServerId()
  self:SetSnappingTargetByActorId(target_actor_id, TargetCharacter)
  return true
end

function SocketSnapComponent:CancelSnap()
  if self.isPlayer then
    return
  end
  if not self.SnappingTargetWeak then
    return
  end
  local targetRef = self.SnappingTargetRef
  if targetRef then
    local targetSnapComp = targetRef:EnsureComponent(SocketSnapComponent)
    table.removeValue(targetSnapComp.SnappedSocket, self.SnappingTargetSocket)
  end
  self:SetSnappingTargetByActorId(nil)
  self.SnappingSocket = nil
  self.SnappingTargetSocket = nil
  self.SnappingSpeed = 0
  self.SnappingAnimation = nil
end

function SocketSnapComponent:IsSnapping()
  return self.SnappingTargetWeak ~= nil
end

function SocketSnapComponent:IsBeingSnapped()
  return next(self.SnappedSocket) ~= nil
end

function SocketSnapComponent:ApplyAttachment()
  if not self.SnappingTargetRef then
    self:ClearAttachment()
    return
  end
  local targetSnapComp = self.SnappingTargetRef:EnsureComponent(SocketSnapComponent)
  local targetModel = self.SnappingTargetRef.viewObj
  if not targetModel then
    return
  end
  if not targetSnapComp.isPlayer and not targetModel.resourceLoaded then
    targetSnapComp:RegisterDeferApplyAttachment(self)
    return
  end
  local originModel = self.owner.viewObj
  if not originModel or not originModel.resourceLoaded then
    return
  end
  local previousParent = originModel:GetAttachParentActor()
  if UE.UObject.IsValid(previousParent) then
    Log.DebugFormat("[SocketSnapComponent] ApplyAttachmentForSnapping with previous parent: %s", previousParent:GetName())
  end
  self.owner:SetCollisionDisable(true, NPCModuleEnum.NpcReasonFlags.ATTACHING)
  UE.URocoAIHelper.ApplyAttachmentForSnapping(originModel, targetModel, self:GetStickSocketName(self.SnappingSocket), targetSnapComp:GetStickSocketName(self.SnappingTargetSocket), self.RelativeTransform, self.SnappingSpeed)
  if self.SnappingAnimation then
    self.owner:PlayAnim(self.SnappingAnimation, 1, 0, 0.1, 0.2, -1)
  end
  if not self.movementModeChangedCallback and originModel.MovementModeChangedDelegate then
    self.movementModeChangedCallback = _G.SimpleDelegateFactory:CreateCallback(self, self.OnMovementModeChanged)
    originModel.MovementModeChangedDelegate:Add(originModel, self.movementModeChangedCallback)
  end
  Log.DebugFormat("[SocketSnapComponent] ApplyAttachment success: %u -> %u", self.owner:GetServerId(), self.SnappingTargetRef and self.SnappingTargetRef:GetServerId() or 0)
end

function SocketSnapComponent:ClearAttachment()
  self:RemoveCallback()
  local originModel = self.owner.viewObj
  if UE.UObject.IsValid(originModel) and UE.UObject.IsA(originModel, UE.ACharacter) then
    local bIgnoreMoveAfterDetach = true
    UE.URocoAIHelper.ClearAttachmentForSnapping(originModel, bIgnoreMoveAfterDetach)
    self.owner:SetCollisionDisable(false, NPCModuleEnum.NpcReasonFlags.ATTACHING)
    if self.SnappingAnimation then
      self.owner:StopAnim(self.SnappingAnimation, 0.1)
    end
  else
    Log.DebugFormat("[SocketSnapComponent] ClearAttachmentForSnapping with no viewObj self=%u", self.owner:GetServerId())
  end
end

function SocketSnapComponent:OnMovementModeChanged(character, preMoveMode, preCustomMode)
  local characterMovement = character.CharacterMovement
  if characterMovement.MovementMode == UE.EMovementMode.MOVE_Custom and characterMovement.CustomMovementMode == UE.ERocoCustomMovementMode.MOVE_Snipping then
    return
  end
  if self.d_DelayApply then
    _G.DelayManager:CancelDelayById(self.d_DelayApply)
  end
  self.d_DelayApply = _G.DelayManager:DelayFrames(1, self.OnDelayApplyAttachment, self)
end

function SocketSnapComponent:OnDelayApplyAttachment()
  self.d_DelayApply = nil
  self:ApplyAttachment()
end

function SocketSnapComponent:RemoveCallback()
  if self.movementModeChangedCallback then
    local view = self.owner.viewObj
    if view and UE.UObject.IsValid(view) then
      view.MovementModeChangedDelegate:Remove(view, self.movementModeChangedCallback)
    end
    self.movementModeChangedCallback = nil
  end
  if self.d_DelayApply then
    _G.DelayManager:CancelDelayById(self.d_DelayApply)
    self.d_DelayApply = nil
  end
end

function SocketSnapComponent:GetRelativeTransformRef()
  return self.RelativeTransform
end

function SocketSnapComponent:SetRelativeRotation(x, y, z)
  self.RelativeTransform.Rotation = UE.FRotator(x, y, z):ToQuat()
end

return SocketSnapComponent
