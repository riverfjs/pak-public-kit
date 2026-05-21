local WorldCombatActionBase = require("NewRoco.Modules.Core.NPC.Actions.WorldCombatActions.WorldCombatActionBase")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local WorldCombatSkillEvent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatSkillEvent")
local Base = WorldCombatActionBase
local DebugDrawServerPos = false
local WorldCombatActionRcd = Base:Extend("WorldCombatActionRcd")

function WorldCombatActionRcd:Ctor(Runner, SkillId, ActionType, ServerInfo)
  Base.Ctor(self, Runner, SkillId, ActionType, ServerInfo)
end

function WorldCombatActionRcd:InternalExecute()
  Base.InternalExecute(self)
  if not (self.Runner and self.ServerInfo) or not self.ServerInfo.skill_id then
    return
  end
  self.needTick = true
  self.rcdAction = self:GetSkillActionByGuid(self.ServerInfo.GUID)
  if not self.rcdAction then
    Log.Error("WorldCombatActionRcd:InternalExecute failed, cannot get valid rcdAction from G6Skill by server guid!!!")
    return
  end
  self.actionType = WorldCombatActionBase.EActionType.duration
  self.actionDuration = self.rcdAction:GetActionLength()
  local SyncSkillTime = self.rcdAction:GetStartTime()
  self.rcdAction:ResetRunningTime()
  self.rcdAction:GetSkillObj():JumpToTargetTime(SyncSkillTime)
  local bNeedMove = self.ServerInfo.ray_end_need_move
  local targetPos = SceneUtils.ServerPos2ClientPos(self.ServerInfo.target_pos)
  self.targetPos = SceneUtils.ConvertAbsoluteToRelative(targetPos)
  local target = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.ServerInfo.ex_target_id) or _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self.ServerInfo.ex_target_id)
  if target then
    targetPos = target:GetActorLocation()
  end
  local targetPosExtra = self.ServerInfo.ex_target_pos and SceneUtils.ServerPos2ClientPos(self.ServerInfo.ex_target_pos) or targetPos
  self.targetPosExtra = SceneUtils.ConvertAbsoluteToRelative(targetPosExtra)
  local bossId = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.GetBossID)
  self.currBoss = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, bossId)
  Log.Debug("WorldCombatActionRcd:InternalExecute", self.targetPos, self.targetPosExtra, self.Runner:GetActorLocation(), (self.targetPos - self.Runner:GetActorLocation()):Size(), (self.targetPosExtra - self.Runner:GetActorLocation()):Size())
  self.rcdAction:ActionStartProcess(self.targetPos, self.targetPosExtra, bNeedMove, false)
  if _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.GetCanDrawDebug) and self.Runner then
    local startPos = self.Runner:GetActorLocation()
    UE.UKismetSystemLibrary.Abs_DrawDebugArrow(_G.UE4Helper.GetCurrentWorld(), startPos, targetPos, 5, UE.FLinearColor(1, 0, 0, 1), self.rcdAction:GetActionLength() + 5.0, 1)
  end
end

function WorldCombatActionRcd:PostExecute()
  Base.PostExecute(self)
  self.Runner:AddEventListener(self, WorldCombatSkillEvent.SKILL_RCD_END, self.Finish)
end

function WorldCombatActionRcd:CheckNeedTick()
  return true
end

function WorldCombatActionRcd:Finish(actionGuid)
  if not self.Runner or not self.rcdAction then
    Log.Debug("WorldCombatActionRcd:Finish. No Runner or rcdAction!", self.Runner, self.rcdAction, actionGuid)
    Base.Finish(self)
    return
  end
  if nil ~= actionGuid and self.rcdAction.GUID ~= actionGuid then
    return
  end
  Log.Debug("WorldCombatActionRcd:Finish", actionGuid, self.rcdAction.GUID)
  self.rcdAction:ActionEndProcess()
  self.Runner:RemoveEventListener(self, WorldCombatSkillEvent.SKILL_RCD_END, self.Finish)
  Base.Finish(self)
end

function WorldCombatActionRcd:OnTick(DeltaTime)
  if not self.rcdAction then
    Log.Debug("WorldCombatActionRcd:OnTick. No rcdAction!")
    return
  end
  if DebugDrawServerPos then
    UE.UKismetSystemLibrary.DrawDebugSphere(self.Runner.viewObj, SceneUtils.ConvertAbsoluteToRelative(SceneUtils.ServerPos2ClientPos(self.ServerInfo.target_pos)), 50, 8, UE.FLinearColor(1, 0, 1, 1), 5)
  end
  local ignoreActors = UE.TArray(UE.AActor)
  local playerList = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_ALL_PLAYER)
  for _, player in ipairs(playerList) do
    if UE.UObject.IsValid(player.viewObj) and player:IsInTogetherMove() and not player:IsTogetherMove2P() and not ignoreActors:Contains(player.viewObj) then
      Log.Debug("WorldCombatActionRcd:OnTick ignoreActors", player.viewObj, player:GetServerId(), table.len(playerList))
      ignoreActors:Add(player.viewObj)
    end
  end
  if self.currBoss and UE.UObject.IsValid(self.currBoss.viewObj) then
    ignoreActors:Add(self.currBoss.viewObj)
  end
  local hideNpcViews = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.GetHideNpcViews)
  for _, view in ipairs(hideNpcViews) do
    if UE.UObject.IsValid(view) and not ignoreActors:Contains(view) then
      ignoreActors:Add(view)
    end
  end
  Log.Debug("WorldCombatActionRcd:OnTick", DeltaTime, self.Runner:GetActorLocation(), ignoreActors)
  self.rcdAction:ActionTickProcess(DeltaTime, ignoreActors)
end

function WorldCombatActionRcd:ProcessPerformOnReConnect(skillId, actionData)
  local worldCombatModule = _G.NRCModuleManager:GetModule("WorldCombatModule")
  if not worldCombatModule then
    return
  end
  if not self.Runner or not self.Runner.viewObj then
    return
  end
  local actionObj = self:GetSkillActionByGuid(actionData.GUID)
  if not UE.UObject.IsValid(actionObj) then
    return
  end
  local newPos = SceneUtils.ServerPos2ClientPos(actionData.rcd_snapshoot.begin_pos)
  self.Runner:SetActorLocation(newPos)
  local rcdInfo = _G.ProtoMessage:newWorldCombatDotsSkillRcdInfo()
  rcdInfo.GUID = actionData.GUID
  rcdInfo.skill_id = skillId
  rcdInfo.target_pos = actionData.jump_snapshoot.target_pos
  rcdInfo.ray_end_need_move = actionObj.bRayEndNeedMove
  rcdInfo.ex_target_pos = actionData.rcd_snapshoot.ex_target_pos
  rcdInfo.ex_target_id = actionData.rcd_snapshoot.ex_target_id
  self.ServerInfo = rcdInfo
  Log.Dump(rcdInfo, 1, "WorldCombatActionRcd:ProcessPerformOnReConnect")
  self:Execute(worldCombatModule)
end

return WorldCombatActionRcd
