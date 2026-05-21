local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.Magic.ScenePlayerMagicBaseBuff")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local MagicMessageUtils = require("NewRoco.Modules.System.MagicMessage.MagicMessageUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local VideoMagicComponent = require("NewRoco.Modules.System.MagicVideo.VideoMagicComponent")
local ShowTrajectory = false
local ScenePlayerVideoBuff = Base:Extend("ScenePlayerVideoBuff")
local TopKFinderNum = 8
local TopKDistance = 800

function ScenePlayerVideoBuff:OnBegin(owner, MagicInfo)
  Base.OnBegin(self, owner, MagicInfo)
  if self.owner == nil or not self.owner.isLocal then
    return
  end
  self.magicInfo.pauseBuff = nil
  self.lastTickValidType = nil
  self.magicInfo.valid = MagicMessageUtils.NpcValidType.UnInited
  self.CreateAngle = MagicMessageUtils.TryGetGlobalConfig(_G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG, "magic_message_create_angle", "num", 15)
  self.CreateHeight = MagicMessageUtils.TryGetGlobalConfig(_G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG, "magic_message_create_height", "num", 50)
  self.CreateDistance = MagicMessageUtils.TryGetGlobalConfig(_G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG, "magic_message_create_range", "num", 300)
  self.AirWallCheckAdditionalDistance = 200
  local teleportRuleId = MagicMessageUtils.TryGetGlobalConfig(_G.DataConfigManager.ConfigTableId.MAP_GLOBAL_CONFIG, "create_magic_teleport_rule_id", "num", 0)
  local teleportConf = _G.DataConfigManager:GetTeleportRulesConf(teleportRuleId)
  if teleportConf and teleportConf.range and teleportConf.range > 0 then
    self.AirWallCheckAdditionalDistance = teleportConf.range
  end
  self.BossAreaCheckRadius = MagicMessageUtils.TryGetGlobalConfig(_G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG, "create_magic_boss_area_distance", "num", 500)
  self:CreateLocalNPC()
end

function ScenePlayerVideoBuff:CreateLocalNPC()
  local refresh_content_id = MagicMessageUtils.GetNpcRefreshContentConf(self.magicInfo)
  if not refresh_content_id then
    return
  end
  local refreshConf = _G.DataConfigManager:GetNpcRefreshContentConf(refresh_content_id, true)
  if nil == refreshConf then
    Log.Error("failed to find npc refresh config", refresh_content_id)
    return
  end
  local Location = self.owner:GetActorLocation()
  if not Location then
    Log.Error("failed to find npc location")
    return
  end
  local pos = SceneUtils.ClientPos2ServerPos(Location)
  local npc = MagicMessageUtils.CreateLocalNPCBySelf(refreshConf.npc_id, pos)
  npc:SetVisible(false)
  npc:AddEventListener(self, NPCModuleEvent.VIEW_LOADED, self.OnNpcLoaded)
  npc:AddEventListener(self, NPCModuleEvent.On_NPC_Destroy, self.OnNpcDestroyed)
  self.magicInfo.npc = npc
end

function ScenePlayerVideoBuff:SetTrajectory(ShouldShow)
  ShowTrajectory = ShouldShow
end

function ScenePlayerVideoBuff:OnTick()
  if self.owner == nil or not self.owner.isLocal then
    _G.UpdateManager:UnRegister(self)
    return
  end
  if self.magicInfo.pauseBuff then
    _G.UpdateManager:UnRegister(self)
    return
  end
  if ShowTrajectory then
    if not (self.magicInfo and self.magicInfo.npc) or not self.magicInfo.npc.viewObj then
      return
    end
    local StartPos = self.magicInfo.npc:GetActorLocation()
    local landInfo = MagicMessageUtils.GetLandInfo(self.magicInfo.npc.viewObj:K2_GetActorLocation())
    if not landInfo then
      return
    end
    local GroundZ = landInfo.position.Z
    local RayLength = math.abs(StartPos.Z - GroundZ)
    local Color = UE4.FLinearColor(0, 1, 0, 1)
    local MaxHeightConf = _G.DataConfigManager:GetGlobalConfig("magic_message_z_distance_max_client", true)
    if MaxHeightConf and MaxHeightConf.num and RayLength > MaxHeightConf.num then
      Color = UE4.FLinearColor(1, 0, 0, 1)
    end
    local EndPos = UE4.FVector(StartPos.X, StartPos.Y, GroundZ)
    UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), StartPos, EndPos, Color, 0.1, 2)
    UE4.UKismetSystemLibrary.PrintString(_G.UE4Helper.GetCurrentWorld(), string.format("[%.2f\231\177\179]", RayLength / 100), true, false, Color, 0.1)
  end
  local npc = self.magicInfo.npc
  if npc and npc.viewObj ~= false and nil ~= npc.viewObj then
    self:UpdateNpcTransform()
    self:CheckNpcValid()
  end
end

function ScenePlayerVideoBuff:OnNpcLoaded(viewObj)
  if not viewObj then
    return
  end
  local npc = viewObj.sceneCharacter
  if not npc then
    return
  end
  if npc:GetComponent(VideoMagicComponent) == nil then
    npc:EnsureComponent(VideoMagicComponent)
  end
  npc:RemoveEventListener(self, NPCModuleEvent.VIEW_LOADED, self.OnNpcLoaded)
  _G.UpdateManager:Register(self)
  self:UpdateNpcTransform()
  self:CheckNpcValid()
  npc:SetVisible(true)
end

function ScenePlayerVideoBuff:OnNpcDestroyed(npc)
  if npc then
    npc:RemoveEventListener(self, NPCModuleEvent.On_NPC_Destroy, self.OnNpcDestroyed)
  end
  self.lastTickValidType = nil
  _G.UpdateManager:UnRegister(self)
end

function ScenePlayerVideoBuff:UpdateNpcTransform()
  local npc = self.magicInfo.npc
  local viewObj = npc.viewObj
  if false == viewObj then
    return
  end
  local caster = self.owner
  local playerPosition = caster.viewObj:K2_GetActorLocation()
  local cameraManager = self.owner:GetUEController().PlayerCameraManager
  local direction = cameraManager:GetCameraRotation():ToVector()
  direction = direction + direction:RotateAngleAxis(self.CreateAngle, _G.FVectorUp)
  local npcTargetOrigin = playerPosition + direction * (self.CreateDistance / 2)
  npcTargetOrigin.Z = npcTargetOrigin.Z + self.CreateHeight
  npc:SetActorLocation(SceneUtils.ConvertRelativeToAbsolute(npcTargetOrigin))
  MagicMessageUtils.NpcSnapToGround(npc, false)
end

function ScenePlayerVideoBuff:CheckNpcValid()
  self.magicInfo.valid = self:GetNpcValidType(self.magicInfo.npc)
  local newValidType = self:ConvertValidType(self.magicInfo.valid)
  if self.lastTickValidType ~= newValidType then
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.SetNpcAppearance, self.magicInfo.npc, newValidType)
  end
  self.lastTickValidType = newValidType
end

function ScenePlayerVideoBuff:GetNpcValidType(npc)
  if nil == npc then
    return MagicMessageUtils.NpcValidType.Invalid
  end
  local viewObj = npc.viewObj
  if false == viewObj or nil == viewObj then
    return MagicMessageUtils.NpcValidType.Invalid
  end
  local origin, extent = MagicMessageUtils.GetActorBounds(viewObj)
  if MagicMessageUtils.CheckAirWallNearby(npc, self.AirWallCheckAdditionalDistance) then
    return MagicMessageUtils.NpcValidType.AirWall
  end
  if MagicMessageUtils.CheckOverlap(npc, origin, extent) then
    return MagicMessageUtils.NpcValidType.Overlap
  end
  if MagicMessageUtils.CheckOnIllegal(npc.viewObj:K2_GetActorLocation()) then
    return MagicMessageUtils.NpcValidType.OnIllegal
  end
  local topKNpcs = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetTopKNpcInCpp, TopKFinderNum, TopKDistance)
  for _, topNpc in ipairs(topKNpcs) do
    if self:ConstValidateTopK(topNpc, npc) and MagicMessageUtils.CheckOverlapNotLoadedCapsule(origin, extent, topNpc) then
      if topNpc.viewObj and topNpc.viewObj.resourceLoaded then
        return MagicMessageUtils.NpcValidType.Overlap
      else
        return MagicMessageUtils.NpcValidType.OverlapNotLoaded
      end
    end
  end
  local StartPos = self.magicInfo.npc:GetActorLocation()
  local waterInfo = MagicMessageUtils.GetWaterInfo(self.magicInfo.npc.viewObj:K2_GetActorLocation())
  local landInfo = MagicMessageUtils.GetLandInfo(self.magicInfo.npc.viewObj:K2_GetActorLocation())
  if landInfo and waterInfo and landInfo.position and waterInfo.position then
    if landInfo.position.Z < waterInfo.position.Z then
      landInfo = waterInfo
    end
  elseif nil == landInfo then
    landInfo = waterInfo
  end
  if not landInfo then
    return
  end
  local GroundZ = landInfo.position.Z
  local RayLength = math.abs(StartPos.Z - GroundZ)
  local MaxHeightConf = _G.DataConfigManager:GetGlobalConfig("magic_message_z_distance_max_client", true)
  if MaxHeightConf and MaxHeightConf.num and RayLength > MaxHeightConf.num then
    return MagicMessageUtils.NpcValidType.TooHigh
  end
  local isLandValid = _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.CheckLandValid, origin)
  if isLandValid == MagicMessageUtils.NpcValidType.Water then
    return isLandValid
  end
  return MagicMessageUtils.NpcValidType.Valid
end

function ScenePlayerVideoBuff:ConvertValidType(type)
  if type == MagicMessageUtils.NpcValidType.Valid or type == MagicMessageUtils.NpcValidType.Water then
    return type
  end
  return MagicMessageUtils.NpcValidType.Invalid
end

function ScenePlayerVideoBuff:ConstValidateTopK(npc, ignore)
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

function ScenePlayerVideoBuff:OnFinish()
  Base.OnFinish(self, true)
  _G.UpdateManager:UnRegister(self)
end

return ScenePlayerVideoBuff
