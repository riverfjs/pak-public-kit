local Base = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local MagicCreationUtils = require("NewRoco.Modules.System.MagicCreation.MagicCreationUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local MagicActionTransferNpcAndSubmitItem = Base:Extend("MagicActionTransferNpcAndSubmitItem")

function MagicActionTransferNpcAndSubmitItem:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
end

function MagicActionTransferNpcAndSubmitItem:Execute()
  Base.Execute(self)
  local player = self:GetPlayer()
  player:PlayAnim("Think2", 1, -1, 0.1, 0.1, -1, -1, "Locomotion")
  _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.OpenTransferNpcPanel, self)
end

function MagicActionTransferNpcAndSubmitItem:Finish(success, data, param)
  local player = self:GetPlayer()
  player:StopAnim("Think2", 0.1, "Locomotion")
  Base.Finish(self, success, data, param)
end

function MagicActionTransferNpcAndSubmitItem:PostOnCommit(rsp)
  if self.bCanceled then
    Log.Debug("MagicActionTransferNpcAndSubmitItem:PostOnCommit has cancaled")
    return
  end
  if not rsp.ret_info then
    Log.Warning("MagicActionTransferNpcAndSubmitItem:PostOnCommit rsp.ret_info == nil")
    return
  end
  if 0 ~= rsp.ret_info.ret_code then
    MagicCreationUtils.UndoDeleteEffect(self.OwnerNpc)
    _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.UnregisterPreperform, self.testNpc)
    Log.Warning("transfer npc failed", rsp.ret_info.ret_code, rsp.ret_info.ret_msg)
  end
  if self.OwnerNpc then
    self.OwnerNpc:RemoveEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnOwnerNpcRemoved)
    if self.OwnerNpc.viewObj then
      self.OwnerNpc.viewObj.hasRecycled = nil
    end
  end
end

function MagicActionTransferNpcAndSubmitItem:CancelSubmit()
  self.bCanceled = true
  self:Finish(false, nil, "0")
end

function MagicActionTransferNpcAndSubmitItem:CheckTransferValid()
  if self.testNpc == nil then
    local config = self.Config
    local refreshContentConf = _G.DataConfigManager:GetNpcRefreshContentConf(tonumber(config.action_param2), true)
    local transform = self.OwnerNpc:GetActorTransform()
    self.testNpc = MagicCreationUtils.CreateLocalNpc(refreshContentConf.npc_id, SceneUtils.ClientPos2ServerPos(transform.Translation))
    self.testNpc:SetHidden(true, NPCModuleEnum.NpcReasonFlags.MagicCreationPerform)
    self.testNpc:AddEventListener(self, NPCModuleEvent.VIEW_LOADED, self.OnTestNpcLoaded)
    self.testNpc.WandId = self.OwnerNpc.WandId
    _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.ApplySuitEffect, self.testNpc)
  else
    self.testNpc.WandId = self.OwnerNpc.WandId
    _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.ApplySuitEffect, self.testNpc)
    self:CheckCanTransfer()
  end
end

function MagicActionTransferNpcAndSubmitItem:OnTestNpcLoaded(viewObj)
  if not self.testNpc then
    return
  end
  self.testNpc:RemoveEventListener(self, NPCModuleEvent.VIEW_LOADED, self.OnTestNpcLoaded)
  self:CheckCanTransfer()
end

function MagicActionTransferNpcAndSubmitItem:CheckCanTransfer()
  local isOverlap = MagicCreationUtils.CheckOverlap(self.testNpc, nil, nil, {
    self.OwnerNpc.viewObj
  }, 10.0)
  if isOverlap then
    self:TransferFailed(MagicCreationUtils.NpcValidType.Overlap)
    return
  end
  local viewObj = self.testNpc.viewObj
  if not viewObj then
    self:TransferFailed(MagicCreationUtils.NpcValidType.UnInited)
    return
  end
  if viewObj.TryAdjustRotationOnTransfer then
    local rotateSuccess = viewObj:TryAdjustRotationOnTransfer()
    if not rotateSuccess then
      self:TransferFailed(MagicCreationUtils.NpcValidType.SpaceNotSufficient)
      return
    end
  end
  self.transform = self.testNpc:GetActorTransform()
  self:PlayTransformAnim()
end

function MagicActionTransferNpcAndSubmitItem:TransferFailed(inValidType)
  Log.Debug("MagicActionTransferNpcAndSubmitItem:TransferFailed", inValidType)
  local reason = MagicCreationUtils.GetInvalidReason(inValidType)
  if reason then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, reason)
  end
  MagicCreationUtils.DeleteLocalNpc(self.testNpc)
  self:CancelSubmit()
end

function MagicActionTransferNpcAndSubmitItem:PlayTransformAnim()
  local Player = self:GetPlayer()
  Player:PlayAnim("WorldLootChest2", 1, 0, 0.1, 0.1, 0, 0, "Locomotion")
  self:NewNpcPreperform()
  local point = SceneUtils.ConvertVectorToPoint(self.transform.Translation)
  local rotator = self.transform.Rotation:ToRotator()
  rotator.Yaw = rotator.Yaw + 360
  if rotator.Yaw > 360 then
    rotator.Yaw = rotator.Yaw - 360
  end
  point.dir = SceneUtils.ClientRotator2ServerPos(rotator)
  local extParam = self:PointToString(point)
  Log.Debug("MagicActionTransferNpcAndSubmitItem:PlayTransformAnim", self.transform.Translation, rotator, extParam)
  self.OwnerNpc:AddEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnOwnerNpcRemoved)
  self:Finish(true, nil, extParam)
end

function MagicActionTransferNpcAndSubmitItem:PointToString(point)
  local pos = string.format("%d,%d,%d", point.pos.x, point.pos.y, point.pos.z)
  if point.dir and point.dir.x and point.dir.y and point.dir.z then
    local dir = string.format("%d,%d,%d", point.dir.x, point.dir.y, point.dir.z)
    return string.format("%s,%s", pos, dir)
  end
  return pos
end

function MagicActionTransferNpcAndSubmitItem:NewNpcPreperform()
  if self.testNpc == nil then
    Log.Warning("MagicActionTransferNpcAndSubmitItem:NewNpcPreperform testNpc == nil", self.OwnerNpc)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.RegisterPreperform, self.testNpc)
  self.testNpc:AddEventListener(self, NPCModuleEvent.On_NPC_Destroy, self.OnNewNpcPreformComplete)
  MagicCreationUtils.PlayCreatingSkill(self.testNpc, self, self.OnCreatingSkillLoaded)
  self:MakeSurePlayerNotStuck()
end

function MagicActionTransferNpcAndSubmitItem:OnCreatingSkillLoaded()
  self.delayVisibleHandle = _G.DelayManager:DelaySeconds(0.05, function()
    self.testNpc:SetHidden(false, NPCModuleEnum.NpcReasonFlags.MagicCreationPerform)
    self.delayVisibleHandle = nil
  end)
  MagicCreationUtils.DoRecycleBp(self.OwnerNpc)
end

function MagicActionTransferNpcAndSubmitItem:OnNewNpcPreformComplete()
  self.testNpc:RemoveEventListener(self, NPCModuleEvent.On_NPC_Destroy, self.OnNewNpcPreformComplete)
  if self.OwnerNpc then
    self.OwnerNpc:SetNotDestroyFlag(false)
    self.OwnerNpc:SetVisible(false)
  end
end

function MagicActionTransferNpcAndSubmitItem:MakeSurePlayerNotStuck()
  if self.testNpc == nil then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  local origin, extent = MagicCreationUtils.GetActorBounds(self.testNpc.viewObj)
  local radius = math.max(extent.X, extent.Y)
  local halfHeight = extent.Z
  local transform = UE4.FTransform()
  transform.Translation = origin
  local blockActor = _G.UE4Helper.GetCurrentWorld():SpawnActor(UE4.ATriggerCapsule, transform, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  if UE4.UObject.IsValid(blockActor) then
    local capsuleComp = blockActor.CollisionComponent
    if UE4.UObject.IsValid(capsuleComp) then
      capsuleComp:SetCapsuleRadius(radius)
      capsuleComp:SetCapsuleHalfHeight(halfHeight)
      capsuleComp:SetCollisionProfileName("NPCStatic")
    end
    self.testNpc.tempBlockActor = blockActor
  end
  local componentFilter = {
    UE.USkeletalMeshComponent,
    UE.UShapeComponent
  }
  local objectTypes = {
    UE.EObjectTypeQuery.Character
  }
  local components = UE4.TArray(UE4.UPrimitiveComponent)
  local bSuccess = UE4.UKismetSystemLibrary.CapsuleOverlapComponents(_G.UE4Helper.GetCurrentWorld(), origin, radius, halfHeight, objectTypes, componentFilter, nil, components)
  if not bSuccess then
    return
  end
  for _, component in tpairs(components) do
    local owner = component:GetOwner()
    local playerViewObj = player.viewObj
    if not owner == player.viewObj then
    else
      local playerPosition = player:GetActorLocation()
      local capsuleComp = playerViewObj.CapsuleComponent
      local playerRadius = 34.0
      local playerHalfHeight = 84.0
      if capsuleComp and UE4.UObject.IsValid(capsuleComp) then
        playerRadius = capsuleComp:GetScaledCapsuleRadius()
        playerHalfHeight = capsuleComp:GetScaledCapsuleHalfHeight()
      end
      local npcLocation = self.testNpc:GetActorLocation()
      local direction = playerPosition - npcLocation
      direction.Z = 0
      direction = direction / direction:Size()
      local distance = radius * 1.05 + playerRadius * 1.05 + 5.0
      playerPosition = npcLocation + direction * distance
      local landInfo = MagicCreationUtils.GetSurfaceInfo(SceneUtils.ConvertAbsoluteToRelative(playerPosition))
      if landInfo then
        playerPosition.Z = _G.UE4Helper.GetCurrentWorld():GetWorldOriginZ() + landInfo.position.Z
      end
      playerPosition.Z = playerPosition.Z + playerHalfHeight + 5.0
      player:SetActorLocation(playerPosition)
      if player.ForceSendMoveReq then
        player:ForceSendMoveReq()
      end
      if _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.GetCanDrawDebug) then
        UE4.UKismetSystemLibrary.DrawDebugCylinder(_G.UE4Helper.GetCurrentWorld(), origin - UE4.FVector(0, 0, halfHeight), origin + UE4.FVector(0, 0, halfHeight), radius, 20, UE4.FLinearColor(0, 1, 0, 1), 15.0, 2)
        UE4.UKismetSystemLibrary.Abs_DrawDebugPoint(_G.UE4Helper.GetCurrentWorld(), playerPosition, 15, UE4.FLinearColor(1, 0.4, 0.2, 0.8), 15.0)
      end
      break
    end
  end
end

function MagicActionTransferNpcAndSubmitItem:OnOwnerNpcRemoved(npc)
  if not npc then
    return
  end
  npc:SetVisible(true)
  npc:SetNotDestroyFlag(true)
end

function MagicActionTransferNpcAndSubmitItem:ShowTips(Code)
  Log.Debug("MagicActionTransferNpcAndSubmitItem:ShowTips", Code)
end

function MagicActionTransferNpcAndSubmitItem:Destroy()
  if self.delayVisibleHandle then
    if self.testNpc then
      self.testNpc:SetHidden(false, NPCModuleEnum.NpcReasonFlags.MagicCreationPerform)
    end
    _G.DelayManager:CancelDelay(self.delayVisibleHandle)
  end
  self.delayVisibleHandle = nil
  Base.Destroy(self)
end

return MagicActionTransferNpcAndSubmitItem
