local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.Magic.ScenePlayerMagicBaseBuff")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local MagicCreationUtils = require("NewRoco.Modules.System.MagicCreation.MagicCreationUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local ScenePlayerCreateBuff = Base:Extend("ScenePlayerCreateBuff")
local TopKFinderNum = 8
local TopKDistance = 800

function ScenePlayerCreateBuff:OnBegin(owner, MagicInfo)
  Base.OnBegin(self, owner, MagicInfo)
  local WandData = owner:GetCurWandDataByMagicType(ProtoEnum.SceneMagicType.SMT_CREATE)
  self.magicInfo.mozhangBP.DisappearFx = WandData.CreateMagicResource.NS_Create_Disappead
  if self.owner == nil or not self.owner.isLocal then
    return
  end
  self.magicInfo.pauseBuff = nil
  self.lastTickValidType = nil
  self.magicInfo.valid = MagicCreationUtils.NpcValidType.UnInited
  self.CreateDistance = MagicCreationUtils.TryGetGlobalConfig(_G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG, "nexus_to_player_distance_when_creating", "num", 100)
  self.AirWallCheckAdditionalDistance = 200
  local teleportRuleId = MagicCreationUtils.TryGetGlobalConfig(_G.DataConfigManager.ConfigTableId.MAP_GLOBAL_CONFIG, "create_magic_teleport_rule_id", "num", 0)
  local teleportConf = _G.DataConfigManager:GetTeleportRulesConf(teleportRuleId)
  if teleportConf and teleportConf.range and teleportConf.range > 0 then
    self.AirWallCheckAdditionalDistance = teleportConf.range
  end
  self:CreateLocalNPC()
end

function ScenePlayerCreateBuff:CreateLocalNPC()
  local refresh_content_id = MagicCreationUtils.GetCreateTargetNpcRefreshId(self.magicInfo)
  if not refresh_content_id then
    return
  end
  local refreshConf = _G.DataConfigManager:GetNpcRefreshContentConf(refresh_content_id, true)
  if nil == refreshConf then
    Log.Error("failed to find npc refresh config", refresh_content_id)
    return
  end
  local npc = MagicCreationUtils.CreateLocalNpc(refreshConf.npc_id, SceneUtils.ClientPos2ServerPos(self.owner:GetActorLocation()))
  npc:AddEventListener(self, NPCModuleEvent.VIEW_LOADED, self.OnNpcLoaded)
  npc:AddEventListener(self, NPCModuleEvent.On_NPC_Destroy, self.OnNpcDestroyed)
  self.magicInfo.npc = npc
  _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.ApplySuitEffect, npc)
end

function ScenePlayerCreateBuff:OnNpcLoaded(viewObj)
  if not viewObj then
    return
  end
  local npc = viewObj.sceneCharacter
  if not npc then
    return
  end
  npc:RemoveEventListener(self, NPCModuleEvent.VIEW_LOADED, self.OnNpcLoaded)
  local areaQueryManager = UE4.UAreaQueryManager.Get(_G.UE4Helper.GetCurrentWorld())
  if areaQueryManager then
    areaQueryManager:RegisterActor(viewObj)
  end
  self:UpdateNpcTransform()
  self:CheckNpcValid()
end

function ScenePlayerCreateBuff:OnNpcDestroyed(npc)
  if npc then
    npc:RemoveEventListener(self, NPCModuleEvent.On_NPC_Destroy, self.OnNpcDestroyed)
  end
  self.lastTickValidType = nil
end

function ScenePlayerCreateBuff:OnUpdate(deltaTime)
  Base.OnUpdate(self, deltaTime)
  if self.owner == nil or not self.owner.isLocal then
    return
  end
  if self.magicInfo.pauseBuff then
    return
  end
  if self.magicInfo.npc and self.magicInfo.npc.viewObj ~= false and nil ~= self.magicInfo.npc.viewObj then
    self:UpdateNpcTransform()
    self:CheckNpcValid()
    if _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.GetCanDrawDebug) then
      local npcLocation = self.magicInfo.npc:GetActorLocation()
      local playerLocation = self.owner:GetActorLocation()
      UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(_G.UE4Helper.GetCurrentWorld(), npcLocation, 5, 20, UE4.FLinearColor(0, 1, 0, 1), deltaTime)
      UE4.UKismetSystemLibrary.Abs_DrawDebugArrow(_G.UE4Helper.GetCurrentWorld(), playerLocation, npcLocation, 10, UE4.FLinearColor(0, 1, 0.1, 1), deltaTime, 5)
    end
  end
end

function ScenePlayerCreateBuff:UpdateNpcTransform()
  local npc = self.magicInfo.npc
  local viewObj = npc.viewObj
  if false == viewObj then
    return
  end
  local caster = self.owner
  local playerPosition = caster.viewObj:K2_GetActorLocation()
  local cameraManager = self.owner:GetUEController().PlayerCameraManager
  local direction = cameraManager:GetCameraRotation():ToVector()
  local radius = viewObj.BoundingRadius or 0.0
  local npcTargetOrigin = playerPosition + direction * (self.CreateDistance + radius)
  self.centerSurfaceInfo = MagicCreationUtils.GetSurfaceInfo(npcTargetOrigin)
  if self.centerSurfaceInfo ~= nil then
    npc:SetActorLocation(SceneUtils.ConvertRelativeToAbsolute(self.centerSurfaceInfo.position))
  else
    npc:SetActorLocation(SceneUtils.ConvertRelativeToAbsolute(npcTargetOrigin))
  end
end

function ScenePlayerCreateBuff:CheckNpcValid()
  self.magicInfo.valid = self:GetNpcValidType(self.magicInfo.npc)
  if MagicCreationUtils.TypeNeedResetHeight(self.magicInfo.valid) then
    local caster = self.owner
    local casterAbsOrigin = caster:GetActorLocation()
    local casterHalfHeight = caster:GetScaledHalfHeight()
    local casterHeight = casterAbsOrigin.Z - casterHalfHeight
    local npcAbsLocation = self.magicInfo.npc:GetActorLocation()
    npcAbsLocation.Z = casterHeight
    self.magicInfo.npc:SetActorLocation(npcAbsLocation)
  end
  local newValidType = self:ConvertValidType(self.magicInfo.valid)
  _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.SetNpcAppearance, self.magicInfo.npc, self.magicInfo.valid)
  self.lastTickValidType = newValidType
end

function ScenePlayerCreateBuff:GetNpcValidType(npc)
  if nil == npc then
    return MagicCreationUtils.NpcValidType.Invalid
  end
  local viewObj = npc.viewObj
  if false == viewObj or nil == viewObj then
    return MagicCreationUtils.NpcValidType.Invalid
  end
  if viewObj.bBannedByArea then
    return MagicCreationUtils.NpcValidType.AreaBan
  end
  local origin, extent = MagicCreationUtils.GetActorBounds(viewObj)
  local isHeightValid = _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.CheckNpcHeightDifferenceWithPlayer, origin, self.centerSurfaceInfo)
  local isLandValid = _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.CheckLandValid, origin, extent, self.centerSurfaceInfo)
  if isLandValid == MagicCreationUtils.NpcValidType.Water then
    return isLandValid
  end
  if isHeightValid ~= MagicCreationUtils.NpcValidType.Valid then
    return isHeightValid
  end
  if isLandValid ~= MagicCreationUtils.NpcValidType.Valid then
    return isLandValid
  end
  if MagicCreationUtils.CheckAirWallNearby(origin, extent, self.AirWallCheckAdditionalDistance) then
    return MagicCreationUtils.NpcValidType.AirWall
  end
  if MagicCreationUtils.CheckOverlap(npc, origin, extent) then
    return MagicCreationUtils.NpcValidType.Overlap
  end
  local actor = self.centerSurfaceInfo.actor
  if actor.FixCoord then
    return MagicCreationUtils.NpcValidType.Overlap
  end
  local topKNpcs = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetTopKNpcInCpp, TopKFinderNum, TopKDistance)
  for _, topNpc in ipairs(topKNpcs) do
    if self:ConstValidateTopK(topNpc, npc) and MagicCreationUtils.CheckOverlapNotLoadedCapsule(origin, extent, topNpc) then
      if topNpc.viewObj and topNpc.viewObj.resourceLoaded then
        return MagicCreationUtils.NpcValidType.Overlap
      else
        return MagicCreationUtils.NpcValidType.OverlapNotLoaded
      end
    end
  end
  if _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.CheckEavesExisted, origin, extent, npc:GetActorRotation(), {
    npc.viewObj
  }) then
    return MagicCreationUtils.NpcValidType.OverlapEaves
  end
  return MagicCreationUtils.NpcValidType.Valid
end

function ScenePlayerCreateBuff:ConvertValidType(type)
  if type == MagicCreationUtils.NpcValidType.Valid then
    return type
  end
  return MagicCreationUtils.NpcValidType.Invalid
end

function ScenePlayerCreateBuff:ConstValidateTopK(npc, ignore)
  if not npc then
    return false
  end
  if ignore and npc == ignore then
    return false
  end
  if npc:GetVisible() and npc.viewObj and npc.viewObj.resourceLoaded then
    return false
  end
  return true
end

return ScenePlayerCreateBuff
