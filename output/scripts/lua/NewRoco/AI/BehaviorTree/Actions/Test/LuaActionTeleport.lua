local Base = require("NewRoco.AI.BehaviorTree.LuaActionBase")
local LuaActionTeleport = Base:Extend("LuaActionTeleport")

function LuaActionTeleport:OnStart(AIController, ...)
  local args = {
    ...
  }
  local owner = AIController
  local target = self.Target:GetValue(owner)
  if math.abs(target.X) > 1.0E9 or math.abs(target.Y) > 1.0E9 then
    if RocoEnv.IS_EDITOR then
      Log.PrintScreenMsg("[AI] %s \229\141\179\229\176\134\228\188\160\233\128\129\229\136\176\229\188\130\229\184\184\231\130\185(x=%.1f,y=%.1f,z=%.1f)", owner.Npc.config.name, target.X, target.Y, target.Z)
    else
      Log.DebugFormat("[AI] %s \229\141\179\229\176\134\228\188\160\233\128\129\229\136\176\229\188\130\229\184\184\231\130\185(x=%.1f,y=%.1f,z=%.1f)", owner.Npc.config.name, target.X, target.Y, target.Z)
    end
    return self:Finish(false)
  end
  local halfHeight = owner.Npc:GetScaledHalfHeight()
  local fixedZ = target.Z
  local TraceStart = target + UE.FVector(0, 0, 200 + halfHeight)
  local TraceEnd = target - UE.FVector(0, 0, 200 + halfHeight)
  local viewObj = owner.Npc.viewObj
  local LandHit, LandSuccess = UE.UKismetSystemLibrary.Abs_LineTraceSingle(viewObj, TraceStart, TraceEnd, UE.ETraceTypeQuery.Land, false, nil, 0, nil, true)
  if LandSuccess then
    fixedZ = LandHit.ImpactPoint.Z + halfHeight
    Log.Debug("LuaActionTeleport:OnStart LandSuccess", owner.Npc:DebugNPCNameAndID(), halfHeight, fixedZ, LandHit.ImpactPoint, LandHit.Actor, LandHit.Component)
  end
  local WaterHit, WaterSuccess = UE.UKismetSystemLibrary.Abs_LineTraceSingle(viewObj, TraceStart, TraceEnd, UE.ETraceTypeQuery.Water, false, nil, 0, nil, true)
  local moveComp = viewObj:GetComponentByClass(UE.UCharacterNavMovementComponent)
  if WaterSuccess and fixedZ < WaterHit.ImpactPoint.Z then
    fixedZ = math.max(WaterHit.ImpactPoint.Z + halfHeight, fixedZ)
    if moveComp and moveComp:IsWalking() then
      moveComp:LuaRequestDirectMove(FVectorDown, false)
    end
  end
  if moveComp and moveComp:IsHovering() then
    fixedZ = fixedZ + moveComp.HoverHeightTarget
  end
  target.Z = fixedZ
  if owner.Npc.tracked then
    Log.PrintScreenMsg("[AI] \228\187\187\229\138\161\230\173\163\229\156\168\232\191\189\232\184\170\231\154\132 %s \229\141\179\229\176\134\228\188\160\233\128\129\229\136\176(x=%.1f,y=%.1f,z=%.1f)", owner.Npc.config.name, target.X, target.Y, target.Z)
  end
  owner.Npc:TeleportToPos(target)
  Log.Debug("LuaActionTeleport:OnStart Final", owner.Npc:DebugNPCNameAndID(), halfHeight, fixedZ, target)
  if self.ReportPos and self.ReportPos:GetValue(owner) then
    owner.Npc:ReportPosition(ProtoEnum.SetNpcPosType.SNPT_AI_TELEPORT)
  end
  self:Finish(true)
end

return LuaActionTeleport
