local WorldCombatActionBase = require("NewRoco.Modules.Core.NPC.Actions.WorldCombatActions.WorldCombatActionBase")
local MissileUtils = require("NewRoco.Modules.Core.Missile.MissileUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local Base = WorldCombatActionBase
local WorldCombatActionMissileLaunch = Base:Extend("WorldCombatActionMissileLaunch")

function WorldCombatActionMissileLaunch:Ctor(Runner, SkillId, ActionType, ServerInfo)
  Base.Ctor(self, Runner, SkillId, ActionType, ServerInfo)
end

function WorldCombatActionMissileLaunch:InternalExecute()
  Base.InternalExecute(self)
  if not (self.Runner and self.ServerInfo) or not self.ServerInfo.skill_id then
    return
  end
  local missileModule = NRCModuleManager:GetModule("MissileModule")
  local target = self:GetTargetByServerInfo()
  local missileData = MissileUtils:NewMissileData()
  missileData.MissileType = self.ServerInfo.missile_type or Enum.MissileType.TRACE_TARGET
  missileData.InitSpeed = self.ServerInfo.speed or 0
  if target and missileData.MissileType ~= Enum.MissileType.TRACE_TARGET then
    target = nil
    Log.Debug("WorldCombatActionMissileLaunch:InternalExecute not trace missile get target id! Make it nil now!", self.ServerInfo.skill_id, missileData.MissileType)
  end
  if missileData.MissileType == Enum.MissileType.TRACE_TARGET then
    missileData.AccelerateSpeed = self.ServerInfo.trace_bullet.accelerate_speed or 0
    missileData.MaxSpeed = self.ServerInfo.trace_bullet.max_speed or missileData.InitSpeed
    missileData.AngleSpeed = self.ServerInfo.trace_bullet.angle_speed or 0
    missileData.CancelTraceDist = self.ServerInfo.trace_bullet.cancel_trace_dist or 0
    missileData.TraceTime = self.ServerInfo.trace_bullet.trace_dur_time or 0
    missileData.IsKeepLandHeight = self.ServerInfo.trace_bullet.is_keep_land_height or false
    missileData.LandHeight = self.ServerInfo.trace_bullet.land_height or 0
  elseif missileData.MissileType == Enum.MissileType.AIM_AT_TARGET_POS then
    missileData.AccelerateSpeed = self.ServerInfo.normal_bullet.accelerate_speed or 0
    missileData.MaxSpeed = self.ServerInfo.normal_bullet.max_speed or missileData.InitSpeed
    missileData.IsKeepLandHeight = self.ServerInfo.normal_bullet.is_keep_land_height or false
    missileData.LandHeight = self.ServerInfo.normal_bullet.land_height or 0
    missileData.AngleSpeed = 0
    missileData.CancelTraceDist = 0
    missileData.TraceTime = 0
  elseif missileData.MissileType == Enum.MissileType.FLY_WITH_CURVE then
    missileData.CurveFlyTime = self.ServerInfo.curve_bullet.curve_fly_time or 0.01
    missileData.AccelerateSpeed = 0
  end
  Log.Debug("WorldCombatActionMissileLaunch:InternalExecute", self.ServerInfo.launch_bullet_id)
  self.missileAction = self:GetSkillActionByGuid(self.ServerInfo.GUID)
  if missileData.MissileType ~= Enum.MissileType.FLY_WITH_CURVE then
    missileModule:LaunchMissileByData(self.ServerInfo.launch_bullet_id, nil, self.Runner, target, UE.FVector(self.ServerInfo.target_pos.x, self.ServerInfo.target_pos.y, self.ServerInfo.target_pos.z), self.SkillId, missileData)
  else
    missileModule:LaunchCurveMissile(self.ServerInfo.launch_bullet_id, nil, self.Runner, target, UE.FVector(self.ServerInfo.target_pos.x, self.ServerInfo.target_pos.y, self.ServerInfo.target_pos.z), self.SkillId, self.missileAction, missileData)
  end
  if _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.GetCanDrawDebug) then
    local missile = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.ServerInfo.launch_bullet_id)
    if missile then
      local serverPos = missile.serverData.base.pt.pos
      local serverLocation = SceneUtils.ServerPos2ClientPos(serverPos)
      local targetLocation = SceneUtils.ServerPos2ClientPos(self.ServerInfo.target_pos)
      local duration = self.ServerInfo.trace_dur_time or 7.0
      UE.UKismetSystemLibrary.Abs_DrawDebugArrow(_G.UE4Helper.GetCurrentWorld(), serverLocation, targetLocation, 10, UE.FLinearColor(0.2, 0.2, 0.8, 1), duration, 2)
      local debugInfo = string.format("%d--%s--%u--%f", self.ServerInfo.skill_id, self.ServerInfo.GUID, self.ServerInfo.launch_bullet_id, self.ServerInfo.cur_launch_time)
      UE.UKismetSystemLibrary.Abs_DrawDebugString(_G.UE4Helper.GetCurrentWorld(), targetLocation, debugInfo, nil, UE.FLinearColor(0.1, 0.1, 0.8, 1), duration)
    end
  end
end

function WorldCombatActionMissileLaunch:ProcessPerformOnReConnect(skillId, actionData)
  local worldCombatModule = _G.NRCModuleManager:GetModule("WorldCombatModule")
  if not worldCombatModule then
    Log.Error("WorldCombatActionMissileLaunch:ProcessPerformOnReConnect worldCombatModule is nil")
    return
  end
  if not self.Runner or not self.Runner.viewObj then
    Log.Error("WorldCombatActionMissileLaunch:ProcessPerformOnReConnect Runner is nil")
    return
  end
  local actionObj = self:GetSkillActionByGuid(actionData.GUID)
  if not UE.UObject.IsValid(actionObj) then
    Log.Error("WorldCombatActionMissileLaunch:ProcessPerformOnReConnect actionObj is nil")
    return
  end
  local missileInfo = _G.ProtoMessage:newWorldCombatDotsSkillMissileLaunchInfo()
  missileInfo.GUID = actionData.GUID
  missileInfo.skill_id = skillId
  missileInfo.missile_type = actionData.missile_snapshoot.missile_type
  missileInfo.speed = actionData.missile_snapshoot.cur_speed or 0
  missileInfo.target_id = actionData.missile_snapshoot.target_id
  missileInfo.target_pos = actionData.missile_snapshoot.target_pos
  missileInfo.cur_launch_time = actionData.missile_snapshoot.cur_launch_time
  if missileInfo.missile_type == Enum.MissileType.TRACE_TARGET then
    missileInfo.AccelerateSpeed = actionData.trace_bullet.accelerate_speed or 0
    missileInfo.MaxSpeed = actionData.trace_bullet.max_speed or missileInfo.speed
    missileInfo.AngleSpeed = actionData.trace_bullet.angle_speed or 0
    missileInfo.CancelTraceDist = actionData.trace_bullet.cancel_trace_dist or 0
    missileInfo.TraceTime = actionData.trace_bullet.trace_dur_time or 0
    missileInfo.IsKeepLandHeight = actionData.trace_bullet.is_keep_land_height or false
    missileInfo.LandHeight = actionData.trace_bullet.land_height or 0
  elseif missileInfo.missile_type == Enum.MissileType.AIM_AT_TARGET_POS then
    missileInfo.AccelerateSpeed = actionData.normal_bullet.accelerate_speed or 0
    missileInfo.MaxSpeed = actionData.normal_bullet.max_speed or missileInfo.speed
    missileInfo.IsKeepLandHeight = actionData.normal_bullet.is_keep_land_height or false
    missileInfo.LandHeight = actionData.normal_bullet.land_height or 0
    missileInfo.AngleSpeed = 0
    missileInfo.CancelTraceDist = 0
    missileInfo.TraceTime = 0
  elseif missileInfo.missile_type == Enum.MissileType.FLY_WITH_CURVE then
    missileInfo.CurveFlyTime = actionData.curve_bullet.curve_fly_time or 0.01
  end
  self.ServerInfo = missileInfo
  Log.Dump(missileInfo, 1, "WorldCombatActionMissileLaunch:ProcessPerformOnReConnect")
  self:Execute(worldCombatModule)
end

return WorldCombatActionMissileLaunch
