local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local WorldCombatSkillContext = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatSkillContext")
local WorldCombatSkillEvent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatSkillEvent")
local WorldCombatState = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatState")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local WorldCombatResLoadComponent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatResLoadComponent")
local ResRequest = require("Core.Service.ResourceManager.ResRequest")
local AIDefines = require("NewRoco.AI.AIDefines")
local Base = ActorComponent
local SkillCache = Class("SkillCache")

function SkillCache:Ctor(owner, skillId, target, targetPos, skillCompleteCallback)
  Base.Ctor(self)
  self.owner = owner
  self.skillId = skillId
  self.target = target
  self.targetPos = targetPos
  self.skillCompleteCallback = skillCompleteCallback
end

function SkillCache:ClearData()
  self.owner = nil
  self.skillId = nil
  self.target = nil
  self.targetPos = nil
  self.skillCompleteCallback = nil
end

local WorldCombatSkillComponent = Base:Extend("WorldCombatSkillComponent")

function WorldCombatSkillComponent:Ctor()
  Base.Ctor(self)
  self.actionTempData = {}
  self.shieldSkillIds = {
    BossShieldNormal = 144,
    BossShieldBroken = 145,
    BossShieldHit = 155,
    NightMareBossShieldHit = 158,
    NightMareBossShieldNormal = 146,
    NightMareBossShieldBroken = 147
  }
end

function WorldCombatSkillComponent:GetActionIdx()
  if not self.currentContext then
    return 1
  end
  return self.currentContext:GetActionIdx()
end

function WorldCombatSkillComponent:TryCastPassiveSkill(skillId, target, targetPos, completeCallback, CompleteCallbackCaster)
  if not self.owner or not UE.UObject.IsValid(self.owner.viewObj) then
    return
  end
  local skillConf = _G.DataConfigManager:GetWorldCombatSkillConf(skillId, true)
  if not skillConf then
    Log.Error("Config data of skill is invalid!!!", skillId)
    return self:SkillFailed(skillId)
  end
  if self.rocoSkillComp == nil then
    self.rocoSkillComp = self.owner.viewObj.RocoSkill
  end
  self.passiveSkillCompleteCallback = completeCallback
  self.passiveSkillCompleteCaller = CompleteCallbackCaster
  if self:StartSkill(skillId, skillConf.skill_ref, self.owner.viewObj, target and target.viewObj or nil, targetPos, true, nil, true) == false then
    Log.Error("WorldCombatSkillComponent:TrayCastPassiveSkill Failed!!!", skillId)
  end
end

function WorldCombatSkillComponent:IsPlayBrokenShieldSkill()
  if not self.currentPassiveContext then
    return false
  end
  if self.currentPassiveContext.skillId == self.shieldSkillIds.BossShieldBroken or self.currentPassiveContext.skillId == self.shieldSkillIds.NightMareBossShieldBroken then
    return true
  end
  return false
end

function WorldCombatSkillComponent:IsPlayNormalShieldSkill()
  if not self.currentPassiveContext then
    return false
  end
  if self.currentPassiveContext.skillId == self.shieldSkillIds.BossShieldNormal or self.currentPassiveContext.skillId == self.shieldSkillIds.NightMareBossShieldNormal then
    return true
  end
  return false
end

function WorldCombatSkillComponent:IsPlayHitShieldSkill()
  if not self.currentPassiveContext then
    return false
  end
  if self.currentPassiveContext.skillId == self.shieldSkillIds.BossShieldHit or self.currentPassiveContext.skillId == self.shieldSkillIds.NightMareBossShieldHit then
    return true
  end
  return false
end

function WorldCombatSkillComponent:TryCastSkill(skillId, target, targetPos, interrupt, blackBoardParams, skillInfo)
  if not interrupt and self.currentContext then
    Log.Error("Owner is casting skill!!!", self.currentContext.skillId)
    return self:SkillFailed(skillId)
  end
  local skillConf = _G.DataConfigManager:GetWorldCombatSkillConf(skillId, true)
  if not skillConf then
    Log.Error("Config data of skill is invalid!!!", skillId)
    return self:SkillFailed(skillId)
  end
  if self:CheckSkillCastValid() ~= Enum.WorldSkillValidResult.WSVR_SUCCESS then
    Log.Error("Skill cast valid failed!!!", skillId)
    return self:SkillFailed(skillId)
  end
  if self.rocoSkillComp == nil then
    self.rocoSkillComp = self.owner.viewObj.RocoSkill
  end
  self:ForceStopCurrentSkill()
  Log.PrintScreenMsg("[WorldCombatSkillComponent] %s TryCastSkill %d %s", self.owner.config.name, skillId, skillConf.skill_ref)
  if self:StartSkill(skillId, skillConf.skill_ref, self.owner.viewObj, target and target.viewObj or nil, targetPos, interrupt, nil, false, skillInfo) == false then
    Log.Error("SkillObj is invalid!!!", skillId)
    return self:SkillFailed(skillId)
  end
  if not self.currentContext then
    self.currentContext = WorldCombatSkillContext(skillId, self.owner, target, targetPos, interrupt)
  end
  self.currentMotionState = WorldCombatState.MotionState.CastSkill
  self.currentContext.SkillStage = Enum.WorldSkillStage.WKS_BEFORE
  self.currentContext.SkillStage = Enum.WorldSkillStage.WKS_LOOP
  self.currentContext.SkillStage = Enum.WorldSkillStage.WKS_MAIM
  self.currentContext.SkillStage = Enum.WorldSkillStage.WKS_AFTER
  self.currentContext.bbCache = blackBoardParams
end

function WorldCombatSkillComponent:StartSkill(skillId, path, casterView, targetView, targetPos, interrupt, parentSkillObj, bPassive, skillInfo)
  local classPath = NRCUtils.FormatBlueprintAssetPath(path)
  if string.IsNilOrEmpty(classPath) then
    return false
  end
  local WorldCombatResLoadComp = self.owner:EnsureComponent(WorldCombatResLoadComponent)
  if bPassive then
    if interrupt then
      local passiveSkills = self.rocoSkillComp:GetCurrentPassiveSkillObjs()
      if self.rocoSkillComp and passiveSkills then
        for i = 1, passiveSkills:Length() do
          local skill = passiveSkills:Get(i)
          if table.contains(self.shieldSkillIds, skill:GetSkillID()) then
            self.rocoSkillComp:CancelSkill(skill, UE4.ESkillActionResult.SkillActionResultInterrupted)
            skill:ClearDelegates()
          end
        end
      end
      self.skillObjPassive = nil
    end
    self.currentPassiveContext = WorldCombatSkillContext(skillId, self.owner, targetView and targetView.sceneCharacter or nil, targetPos, interrupt)
    self.currentPassiveContext.bPassive = true
    self.currentPassiveContext.skillPath = classPath
  else
    self.currentContext = WorldCombatSkillContext(skillId, self.owner, targetView and targetView.sceneCharacter or nil, targetPos, interrupt)
    self.currentContext.skillInfo = skillInfo
  end
  self.parentSkillObj = parentSkillObj
  Log.Debug("WorldCombatSkillComponent:StartSkill", skillId, path, casterView, targetView, targetPos)
  local skillClass = WorldCombatResLoadComp:GetSkillClassByPath(classPath)
  if skillClass then
    local resRequest = ResRequest()
    resRequest.assetPath = classPath
    self:SkillLoadSuccess(resRequest, skillClass)
    return true
  end
  if _G.NRCResourceManager then
    self.skillRequest = _G.NRCResourceManager:LoadResAsync(self, classPath, PriorityEnum.Active_World_Combat_Boss, 10, self.SkillLoadSuccess, self.SkillLoadFailed)
  else
    skillClass = UE.UClass.Load(classPath)
    if not skillClass then
      Log.Error("Cannot find skill class!", classPath)
      self:SkillPlayFailed()
      return false
    end
    self:SkillLoadSuccess(nil, skillClass)
  end
  if _G.WorldCombatModuleCmd and _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsInOfflineMode) then
    SceneUtils:DebugOpenCollision(self.owner.viewObj)
    if targetView then
      SceneUtils:DebugOpenCollision(targetView)
    end
  end
  return true
end

function WorldCombatSkillComponent:SkillLoadFailed(req, msg)
  if self.currentPassiveContext and self.currentPassiveContext.bPassive and self.currentPassiveContext.skillPath == req.assetPath then
    Log.Error("WorldCombatSkillComponent:SkillLoadFailed", req.assetPath)
    return
  end
  self:SkillPlayFailed()
end

function WorldCombatSkillComponent:SkillLoadSuccess(req, asset)
  if not self.owner or not UE.UObject.IsValid(self.owner.viewObj) then
    return
  end
  self.owner:SendEvent(WorldCombatSkillEvent.SKILL_CLASS_LOADED, asset)
  local skillClass = asset
  if self.rocoSkillComp == nil then
    self.rocoSkillComp = self.owner.viewObj.RocoSkill
  end
  if not self.rocoSkillComp then
    Log.Error("Cannot find RocoSkillComponent from BP!")
    return self:SkillPlayFailed()
  end
  if self.currentPassiveContext and self.currentPassiveContext.bPassive and self.currentPassiveContext.skillPath == req.assetPath then
    self:OnPassiveSkillLoadSuccess(req, asset)
    return
  end
  if not self.currentContext then
    Log.Error("Cannot find SkillContext")
    return self:SkillPlayFailed()
  end
  self.skillObj = self.rocoSkillComp:FindOrAddSkillObj(skillClass)
  if _G.RocoEnv.IS_EDITOR and self.parentSkillObj then
    UE.UNRCStatics.SkillObjCopySkillEditor(self.skillObj, self.parentSkillObj)
  end
  if not self.skillObj then
    Log.Error("cannot find skill from RocoSkillComponent!")
    return self:SkillPlayFailed()
  end
  if not self.skillObj.SetCaster then
    Log.Error("SkillObj is corrupt!")
    return self:SkillPlayFailed()
  end
  self.skillObj:SetCaster(self.currentContext.caster.viewObj)
  if self.currentContext.target then
    self.skillObj:SetTargets({
      self.currentContext.target.viewObj
    })
  end
  local hidComp = self.owner.HiddenComponent
  if hidComp then
    local mimicTarget = hidComp:GetMimicObject()
    if mimicTarget then
      self.skillObj.Blackboard:SetValueAsNoDestroyObject("MimicTarget", mimicTarget)
    end
  end
  local bossShieldComp = self.owner.ShieldComponent
  if bossShieldComp then
    local shieldActor = bossShieldComp.Shield
    if shieldActor and UE.UObject.IsValid(shieldActor) then
      self.skillObj.Blackboard:SetValueAsNoDestroyObject("ShieldTarget", shieldActor)
    end
  end
  self.skillObj:SetLocation(self.currentContext.targetPos)
  self.skillObj:SetSkillID(self.currentContext.skillId)
  if self.currentContext.bbCache then
    for k, v in pairs(self.currentContext.bbCache) do
      self.skillObj:GetBlackboard():SetValueAsInt(k, v)
    end
  end
  self.skillObj.IsSkipMeleeBackswing = true
  self.skillObj.CanInterrupt = self.currentContext.canInterrupt
  self.skillObj:ClearDelegates()
  self.skillObj:RegisterEventCallback("PreEnd", self, self.SkillComplete)
  self.skillObj:RegisterEventCallback("End", self, self.SkillComplete)
  self.skillObj:RegisterEventCallback("Interrupt", self, self.SkillComplete)
  self.owner:SendEvent(WorldCombatSkillEvent.SKILL_CAST_START, self.currentContext.skillId, self.skillObj)
  local result = self.rocoSkillComp:LoadAndPlaySkill(self.skillObj)
  if result ~= UE.ESkillStartResult.Success then
    Log.Error("failed to play skill! result=", UE.ESkillStartResult:GetNameByValue(result), "id=", self.currentContext.skillId)
    return self:SkillPlayFailed()
  end
  self:PreLoadSkillResAsync()
  if self.currentContext.skillInfo and self.currentContext.skillInfo.skill_id and self.currentContext.skillId == self.currentContext.skillInfo.skill_id and self.skillObj.GetSkillID and self.skillObj:GetSkillID() == self.currentContext.skillInfo.skill_id then
    UE.UNRCStatics.SkillObjJumpTime(self.skillObj, self.currentContext.skillInfo.current_time)
    local LocationList = {}
    for idx, targetGroup in pairs(self.currentContext.skillInfo.target_group) do
      local LocationInfo = _G.ProtoMessage:newSelectPosInfo()
      LocationInfo.point_idx = idx
      LocationInfo.target_pos = targetGroup.target_pos
      table.insert(LocationList, LocationInfo)
    end
    self.skillObj:ClearData()
    self.skillObj:SetSelectLocations(LocationList)
    local WorldCombatActionFactory = require("NewRoco.Modules.Core.NPC.Actions.WorldCombatActions.WorldCombatActionFactory")
    if not self.currentContext.skillInfo.actions_data then
      return
    end
    for _, actionData in pairs(self.currentContext.skillInfo.actions_data) do
      WorldCombatActionFactory:DispatchActionOnReconnect(self.owner, self.currentContext.skillInfo.skill_id, actionData)
    end
  end
end

function WorldCombatSkillComponent:OnPassiveSkillLoadSuccess(req, asset)
  local skillClass = asset
  self.skillObjPassive = self.rocoSkillComp:FindOrAddSkillObj(skillClass)
  if not self.skillObjPassive then
    Log.Error("cannot find skill from RocoSkillComponent!")
  end
  if not self.skillObjPassive.SetCaster or not UE.UObject.IsValid(self.skillObjPassive) then
    Log.Error("skillObjPassive is corrupt!")
    return
  end
  self.skillObjPassive:SetCaster(self.currentPassiveContext.caster.viewObj)
  if self.currentPassiveContext.target then
    self.skillObjPassive:SetTargets({
      self.currentPassiveContext.target.viewObj
    })
  end
  self.skillObjPassive:SetLocation(self.currentPassiveContext.targetPos)
  self.skillObjPassive:SetSkillID(self.currentPassiveContext.skillId)
  self.skillObjPassive.IsSkipMeleeBackswing = true
  self.skillObjPassive.CanInterrupt = self.currentPassiveContext.canInterrupt
  self.skillObjPassive:SetPassive(true)
  self.skillObjPassive:ClearDelegates()
  self.skillObjPassive:RegisterEventCallback("PreEnd", self, self.OnPassiveSkillEnd)
  self.skillObjPassive:RegisterEventCallback("End", self, self.OnPassiveSkillEnd)
  self.skillObjPassive:RegisterEventCallback("Interrupt", self, self.OnPassiveSkillEnd)
  local result = self.rocoSkillComp:LoadAndPlaySkill(self.skillObjPassive)
  if result ~= UE.ESkillStartResult.Success then
    Log.Error("failed to play skill! result=", UE.ESkillStartResult:GetNameByValue(result), "id=", self.currentPassiveContext.skillId)
  end
  self.currentPassiveContext.bPassive = false
end

function WorldCombatSkillComponent:PreLoadSkillResAsync()
  if not UE.UObject.IsValid(self.skillObj) then
    return
  end
  local actions = self.skillObj:GetAllActions()
  for i = 1, actions:Length() do
    local action = actions:Get(i)
    if type(action.PreLoadActionResAsync) == "function" then
      action:PreLoadActionResAsync()
    end
    if "function" == type(action.CheckEnableInWorldCombat) then
      Log.Debug("RocoSkillAction:CheckEnableInWorldCombat from PreLoadSkillResAsync", i)
      action:CheckEnableInWorldCombat()
    end
  end
end

function WorldCombatSkillComponent:ForceStopCurrentSkill()
  if not UE.UObject.IsValid(self.rocoSkillComp) then
    self:ReleaseData()
    return
  end
  self.isReadyToPerformSkill = nil
  if self.skillObj then
    self.rocoSkillComp:CancelSkill(self.skillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
  end
  if self.performSkillObj then
    self.rocoSkillComp:CancelSkill(self.performSkillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
  end
  local CurrActiveSkill
  if self.rocoSkillComp and UE4.UObject.IsValid(self.rocoSkillComp) then
    CurrActiveSkill = self.rocoSkillComp:GetActiveSkill()
  end
  if CurrActiveSkill and CurrActiveSkill ~= self.skillObjPassive then
    self.rocoSkillComp:CancelSkill(CurrActiveSkill, UE4.ESkillActionResult.SkillActionResultInterrupted)
  end
  if self.owner and self.owner.StopAllMontage then
    self.owner:StopAllMontage(0.1)
  end
  self.currentMotionState = WorldCombatState.MotionState.Idle
  self:ReleaseData()
end

function WorldCombatSkillComponent:ForceStopPassiveSkill()
  if UE.UObject.IsValid(self.rocoSkillComp) and self.skillObjPassive then
    self.rocoSkillComp:CancelSkill(self.skillObjPassive, UE4.ESkillActionResult.SkillActionResultInterrupted)
  end
end

function WorldCombatSkillComponent:OnServerValidBack(result)
  if result ~= Enum.WorldSkillValidResult.WSVR_SUCCESS then
    self:ForceStopCurrentSkill()
  end
end

function WorldCombatSkillComponent:SkillComplete(name, skill)
  Log.Debug("WorldCombatSkillComponent:SkillComplete", name, skill:GetSkillID())
  if self.isReadyToPerformSkill then
    Log.Warning("WorldCombatSkillComponent:SkillComplete isReadyToPerformSkill")
    return
  end
  if not self.currentContext then
    Log.Warning("WorldCombatSkillComponent:SkillComplete no currentContext")
    return
  end
  if not self.owner then
    Log.Warning("WorldCombatSkillComponent:SkillComplete no owner")
    return
  end
  if self.currentContext.SkillStage > Enum.WorldSkillStage.WKS_MAIM then
    self:SkillSuccess()
  else
    self.owner:SendEvent(WorldCombatSkillEvent.SKILL_CAST_END, self.currentContext.skillId)
  end
  self.currentMotionState = WorldCombatState.MotionState.Idle
  if self.skillCompleteCallback then
    self.skillCompleteCallback(self.skillCompleteCallbackCaster, self.currentContext.skillId, true)
  end
  self:ReleaseData()
end

function WorldCombatSkillComponent:SkillSuccess()
  if not self.owner then
    return
  end
  self.owner:SendEvent(WorldCombatSkillEvent.SKILL_CAST_SUCCESS, self.currentContext.skillId)
  self.owner:SendEvent(WorldCombatSkillEvent.SKILL_CAST_END, self.currentContext.skillId)
end

function WorldCombatSkillComponent:SkillFailed(skillId)
  if self.owner then
    self.owner:SendEvent(WorldCombatSkillEvent.SKILL_CAST_FAIL, skillId)
  end
end

function WorldCombatSkillComponent:SkillPlayFailed()
  if self.currentContext then
    local skillId = self.currentContext.skillId
    if self.skillCompleteCallback then
      self.skillCompleteCallback(self.skillCompleteCallbackCaster, skillId, false)
    end
    self:ReleaseData()
    self:SkillFailed(skillId)
  end
end

function WorldCombatSkillComponent:OnPassiveSkillEnd(Name, SkillObj)
  local bSuccess = true
  if "Interrupt" == Name then
    bSuccess = false
  end
  if self.passiveSkillCompleteCallback and self.currentPassiveContext then
    self.passiveSkillCompleteCallback(self.passiveSkillCompleteCaller, self.currentPassiveContext.skillId, bSuccess)
  end
  self:ReleasePassiveData()
end

function WorldCombatSkillComponent:CheckSkillCastValid()
  if self.currentMotionState == WorldCombatState.MotionState.Dizzy or self.currentMotionState == WorldCombatState.MotionState.BeatOff then
    return Enum.WorldSkillValidResult.WSVR_STATE_ERROR
  end
  if self:CheckInCooldown() then
    return Enum.WorldSkillValidResult.WSVR_COOLDOWN_ERROR
  end
  if self:CheckTagDisable() then
    return Enum.WorldSkillValidResult.WSVR_TAG_ERROR
  end
  if not self:CheckResourceEnough() then
    return Enum.WorldSkillValidResult.WSVR_RES_ERROR
  end
  return Enum.WorldSkillValidResult.WSVR_SUCCESS
end

function WorldCombatSkillComponent:CheckInCooldown()
  return false
end

function WorldCombatSkillComponent:CheckTagDisable()
  return false
end

function WorldCombatSkillComponent:CheckResourceEnough()
  return true
end

function WorldCombatSkillComponent:IsPlayingSkill(skillId)
  if not self.currentContext then
    return false
  end
  if self.currentContext.skillId ~= skillId then
    return false
  end
  return true
end

function WorldCombatSkillComponent:CurrSkillPerformOnReconnect(ServerData)
  local skillInfo = ServerData.world_combat_skill_info
  if not skillInfo then
    return
  end
  local skillId = skillInfo.skill_id
  if not skillId or 0 == skillId then
    return
  end
  self.serverDataCache = ServerData
  if not self.owner or not UE.UObject.IsValid(self.owner.viewObj) then
    self.owner:AddEventListener(self, NPCModuleEvent.VIEW_LOADED, self.OnViewLoaded)
    return
  end
  self:DoSkillPerformOnReconnect(ServerData)
end

function WorldCombatSkillComponent:OnViewLoaded(npc)
  if self.owner ~= npc or not self.serverDataCache then
    return
  end
  self:DoSkillPerformOnReconnect()
end

function WorldCombatSkillComponent:DoSkillPerformOnReconnect(ServerData)
  ServerData = ServerData or self.serverDataCache
  if not ServerData then
    return
  end
  local skillInfo = ServerData.world_combat_skill_info
  if not skillInfo then
    return
  end
  local newPos = SceneUtils.ServerPos2ClientPos(skillInfo.caster_pos.pos) + UE.FVector(0, 0, self.owner:GetScaledHalfHeight())
  local newRot = SceneUtils.ServerDir2ClientRotator(skillInfo.caster_pos.dir.z)
  Log.Debug("WorldCombatSkillComponent:DoSkillPerformOnReconnect", SceneUtils.ServerPos2ClientPos(skillInfo.caster_pos.pos), skillInfo.skill_id, newPos, newRot)
  self.owner:SetActorLocation(newPos)
  self.owner:SetActorRotation(newRot)
  local target = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, skillInfo.target_id)
  target = target or _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, skillInfo.target_id)
  local npcConfig = _G.DataConfigManager:GetNpcConf(ServerData.npc_base.npc_cfg_id)
  if npcConfig and npcConfig.genre ~= _G.Enum.ClientNpcType.CNT_BULLET then
    self:TryCastSkill(skillInfo.skill_id, target, SceneUtils.ServerPos2ClientPos(skillInfo.target_pos), true, nil, skillInfo)
  else
    local WorldCombatActionFactory = require("NewRoco.Modules.Core.NPC.Actions.WorldCombatActions.WorldCombatActionFactory")
    for _, actionData in pairs(skillInfo.actions_data) do
      if actionData.skill_action_type == ProtoEnum.SkillActionType.WorldCombatDotsSkillMissile then
        local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, ServerData.npc_base.src_npc_id)
        WorldCombatActionFactory:DispatchActionOnReconnect(caster, skillInfo.skill_id, actionData)
      end
    end
  end
end

function WorldCombatSkillComponent:ReleaseData()
  if self.currentContext then
    self.currentContext:CleanUp()
  end
  if self.skillRequest then
    _G.NRCResourceManager:UnLoadRes(self.skillRequest)
    self.skillRequest = nil
  end
  self.currentContext = nil
  if self.skillObj then
    self.skillObj:ClearSelectLocations()
  end
  self.skillObj = nil
  self.parentSkillObj = nil
end

function WorldCombatSkillComponent:ReleasePassiveData()
  if self.currentPassiveContext then
    self.currentPassiveContext:CleanUp()
    self.currentPassiveContext = nil
  end
  self.skillObjPassive = nil
end

function WorldCombatSkillComponent:DeAttach()
  Base.DeAttach(self)
  self.owner:RemoveEventListener(self, NPCModuleEvent.VIEW_SHELL_LOADED, self.DelayCastChildNpcSkill)
  self:ForceStopCurrentSkill()
  self.isReadyToPerformSkill = nil
  self.owner = nil
  self.skillObj = nil
  self.performSkillObj = nil
  self.rocoSkillComp = nil
  self.actionTempData = {}
end

function WorldCombatSkillComponent:PlayPerformSkill(SkillClass)
  if not SkillClass then
    return
  end
  self.isReadyToPerformSkill = true
  local SkillComp = self.rocoSkillComp or self.owner.viewObj.RocoSkill
  self.skillObj = SkillComp:GetActiveSkill()
  if self.skillObj then
    SkillComp:CancelSkill(self.skillObj, UE.ESkillActionResult.SkillActionResultInterrupted)
  end
  local PerformSkill = SkillComp:FindOrAddSkillObj(SkillClass)
  local skillId = 0
  if self.skillObj then
    skillId = self.skillObj:GetSkillID()
  end
  PerformSkill:SetSkillID(skillId)
  PerformSkill:SetCaster(self.owner.viewObj)
  PerformSkill:ClearDelegates()
  PerformSkill:RegisterEventCallback("End", self, self.OnPerformSkillEnd)
  PerformSkill:RegisterEventCallback("PreEnd", self, self.OnPerformSkillEnd)
  PerformSkill:RegisterEventCallback("PreEndAnim", self, self.OnPerformSkillEnd)
  PerformSkill:RegisterEventCallback("Interrupt", self, self.OnPerformSkillEnd)
  self.performSkillObj = PerformSkill
  self.performSkillObj.CanInterrupt = true
  SkillComp:PlaySkill(PerformSkill)
end

function WorldCombatSkillComponent:OnPerformSkillEnd(Name, Skill)
  self.performSkillObj = nil
  self.isReadyToPerformSkill = false
  self:SkillComplete(Name, Skill)
end

function WorldCombatSkillComponent:sendCallBack(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    self:Log("net ret_code = %d", rsp.ret_info.ret_code)
  end
end

local EnableLog = true

function WorldCombatSkillComponent:Log(msg, ...)
  if EnableLog then
    if self.owner and self.owner.config then
      msg = string.format("[WorldCombatSkillComponent] sid=%u name=%s %s", self.owner.serverData.base.actor_id, self.owner.config.name, msg)
    else
      msg = string.format("[WorldCombatSkillComponent] no owner %s", msg)
    end
    Log.PrintScreenMsg(msg, ...)
  end
end

function WorldCombatSkillComponent:OnBuffAction(skillId, actionIdx, caster, operateType, buffId, duration, durationChange, effectTickInterval)
  local req = ProtoMessage:newZoneSceneWorldCombatSkillBuffReq()
  req.npc_id = caster.serverData.base.actor_id
  req.skill_buff_info.action_idx = actionIdx
  req.skill_buff_info.operate_type = operateType
  req.skill_buff_info.buff_id = buffId
  req.skill_buff_info.skill_id = skillId
  req.skill_buff_info.caster_id = caster.serverData.base.actor_id
  req.skill_buff_info.target_id = self.owner.serverData.base.actor_id
  req.skill_buff_info.duration = duration
  req.skill_buff_info.duration_change = durationChange
  req.skill_buff_info.effect_tick_interval = effectTickInterval
  ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_COMBAT_SKILL_BUFF_REQ, req, self, self.sendCallBack, false, true)
end

function WorldCombatSkillComponent:OnSkillCollisionAction(caster, target, skillId, actionIdx, lastHitDir, impactForce)
  if GlobalConfig.DisablePetDamage then
    return
  end
  local req = ProtoMessage:newZoneSceneWorldCombatHitReq()
  req.victim_id = target and target:GetServerId() or 0
  req.hit_info.skill_id = skillId
  req.hit_info.attacker_id = caster and caster:GetServerId() or 0
  req.hit_info.action_idx = actionIdx or 0
  req.hit_info.hit_dir = lastHitDir
  req.hit_info.impact_force = impactForce
  ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_COMBAT_HIT_REQ, req, self, self.sendCallBack, false, true)
end

function WorldCombatSkillComponent:OnSkillSpawnNpcAction(skillId, actionIdx, contentId, initPos, initRot)
  local req = ProtoMessage:newZoneSceneWorldCombatSkillSpawnNpcReq()
  req.npc_id = self.owner.serverData.base.actor_id
  req.skill_spawn_npc_info.skill_id = skillId
  req.skill_spawn_npc_info.action_idx = actionIdx
  req.skill_spawn_npc_info.content_id = contentId
  req.skill_spawn_npc_info.init_pos = initPos
  req.skill_spawn_npc_info.init_dir = initRot
  ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_COMBAT_SKILL_SPAWN_NPC_REQ, req, self, self.sendCallBack, false, true)
end

function WorldCombatSkillComponent:GetCurrentSkillId()
  if not self.currentContext then
    return false
  end
  local skillId = self.currentContext.skillId
  if not skillId and self.skillObj then
    skillId = self.skillObj:GetSkillID()
  end
  return skillId
end

function WorldCombatSkillComponent:ClientTryCastSkill(skillId, target, targetPos, skillCompleteCallback)
  if not skillId then
    Log.Error("ClientTryCastSkill: skillId is invalid!!!", skillId)
    if skillCompleteCallback then
      skillCompleteCallback(skillId, false)
    end
    return self:SkillFailed(skillId)
  end
  local skillConf = _G.DataConfigManager:GetWorldCombatSkillConf(skillId, true)
  if not skillConf then
    Log.Debug("ClientTryCastSkill: Config data of skill is invalid!!!", skillId)
    if skillCompleteCallback then
      skillCompleteCallback(skillId, false)
    end
    return self:SkillFailed(skillId)
  end
  if not skillConf.skill_ref then
    Log.Debug("ClientTryCastSkill: skill_ref is invalid!!!", skillId)
    if skillCompleteCallback then
      skillCompleteCallback(skillId, false)
    end
    return self:SkillFailed(skillId)
  end
  if not self.owner or not self.owner.viewObj then
    Log.Debug("ClientTryCastSkill: viewObj of owner is invalid!!!", skillId)
    if self.owner.config.genre == Enum.ClientNpcType.CNT_BOSS_SKILL_ITEM then
      self.cacheSkillData = SkillCache(self, skillId, target, targetPos, skillCompleteCallback)
      self.owner:AddEventListener(self, NPCModuleEvent.VIEW_SHELL_LOADED, self.DelayCastChildNpcSkill)
    end
    return self:SkillFailed(skillId)
  end
  if self.rocoSkillComp == nil then
    self.rocoSkillComp = self.owner.viewObj.RocoSkill
  end
  if self.owner.TurnComponent then
    self.owner.TurnComponent:StopTurn(AIDefines.ActionResult.Aborted, true)
  end
  _G.NRCModeManager:DoCmd(_G.WorldCombatModuleCmd.ClearWaitLerpActions)
  self:ForceStopCurrentSkill()
  self.currentContext = WorldCombatSkillContext(skillId, self.owner, target, targetPos, false)
  self:StartSkill(skillId, skillConf.skill_ref, self.owner.viewObj, target, targetPos, false)
  self.skillCompleteCallback = skillCompleteCallback
end

function WorldCombatSkillComponent:DelayCastChildNpcSkill(ChildNpc)
  if self.owner ~= ChildNpc then
    return
  end
  if self.cacheSkillData and self.cacheSkillData.skillId then
    self:ClientTryCastSkill(self.cacheSkillData.skillId, self.cacheSkillData.target, self.cacheSkillData.targetPos, self.cacheSkillData.skillCompleteCallback)
    self.cacheSkillData:ClearData()
    self.cacheSkillData = nil
  end
end

function WorldCombatSkillComponent:ClientTryEndSkill(skillId)
  if not self.skillObj or self.skillObj:GetSkillID() ~= skillId then
    Log.Debug("ClientTryEndSkill failed, Current playing skill dose not match, ServerId: %s", skillId)
    return
  end
  self:ForceStopCurrentSkill()
end

return WorldCombatSkillComponent
