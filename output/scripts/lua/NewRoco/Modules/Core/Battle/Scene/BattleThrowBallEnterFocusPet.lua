local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleTimeoutCounter = require("NewRoco.Modules.Core.Battle.Common.BattleTimeoutCounter")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local BattleThrowBallEnterFocusPet = NRCClass:Extend("BattleThrowBallEnterFocusPet")

function BattleThrowBallEnterFocusPet:Ctor()
  self.timeoutCounter = BattleTimeoutCounter.Get("BattleThrowBallEnterFocusPetTimeoutCounter")
end

function BattleThrowBallEnterFocusPet:DoFocus(SceneCharacter, isBack, aiStatus)
  _G.UpdateManager:Register(self)
  self.timeoutCounter:Start(5, self, self.OnTimeoutHandle, self.OnTimeoutHandle)
  self:releaseFocus()
  self.isFocusing = true
  local Player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.Player = Player
  self.canPlayFocus = true
  self.isBack = isBack
  self.aiStatus = aiStatus
  local npcobj = SceneCharacter
  self.npcobj = npcobj
  local enterSkillPath = BattleConst.Define.ThrowFrontEnterFirst
  if isBack then
    enterSkillPath = BattleConst.Define.ThrowBackEnterFirst
  end
  local skillComp = Player.viewObj.RocoSkill
  local skill = RocoSkillProxy.Create(enterSkillPath, skillComp)
  Log.Debug("BattleThrowBallEnterFocusPet:DoFocus", skill)
  if not skill then
    Log.Error("BattleThrowBallEnterFocusPet:DoFocus, not skill!!")
    return
  end
  local playerIsReady = true
  for _, status in pairs(BattleConst.NoAnimStatus) do
    if Player.statusComponent:HasStatus(status) then
      playerIsReady = false
    end
  end
  self:CreateCameraPos()
  skill:SetWithLoadAndPlay(true)
  skill:SetCaster(playerIsReady and Player.viewObj)
  skill:SetTargets({
    npcobj.viewObj
  })
  skill:RegisterRawCallback(self, self.OnSkillEvent)
  skill:SetPassive(true)
  skill:PlaySkill(self, self.LoadSkillOver)
  self.skillProxy = skill
  self:SaveBlackBoardValues()
end

function BattleThrowBallEnterFocusPet:releaseFocus()
  Log.Error("BattleThrowBallEnterFocusPet:releaseFocus()")
  self.isFocusing = false
  self.canPlayFocus = false
  if self.skillProxy then
    self.skillProxy:CancelSkill(UE4.ESkillActionResult.SkillActionResultInterrupted)
    self.skillProxy:Destroy()
    self:ReleaseRef()
  end
  _G.UpdateManager:UnRegister(self)
end

function BattleThrowBallEnterFocusPet:StopTimer()
  self.timeoutCounter:Stop()
end

function BattleThrowBallEnterFocusPet:PauseTimer()
  self.timeoutCounter:Pause()
end

function BattleThrowBallEnterFocusPet:ResumeTimer()
  self.timeoutCounter:Resume()
end

function BattleThrowBallEnterFocusPet:OnPlayPetAnimEmotion()
  local npc = self:GetTargetNPC()
  if npc and not BattleUtils.CheckPlayerEnterBattleInSky() then
    local animName
    local status = self:GetEnemyAIStatus()
    if BattleUtils.IsBattleAIStatus(status) then
      return
    end
    status = self:GetLastAiStatus(status)
    if status then
      animName = BattleConst.EnterAnimName[status + 1]
    else
      Log.Error("\230\138\149\230\142\183\232\191\155\230\136\152\230\150\151\228\184\173ai_status \228\184\186\231\169\186")
      animName = BattleConst.EnterAnimName[1]
    end
    npc:PlayAnim(animName or BattleConst.EnterAnimName[1], 1, 0, 0.25, 0.25, 1, 0)
  end
end

function BattleThrowBallEnterFocusPet:GetLastAiStatus(status)
  if not status or status <= 0 then
    return 0
  end
  local realAIStatus = 0
  local realAIStatusPriority = 0
  local enterBattles = _G.DataConfigManager:GetAllByName("ENTERBATTLE_BUFF_PRIORITY")
  for _, v in pairs(enterBattles) do
    if status & 1 << v.ai_status > 0 and (0 == realAIStatus or realAIStatusPriority < v.buff_priority) then
      realAIStatus = v.ai_status
      realAIStatusPriority = v.buff_priority
    end
  end
  return realAIStatus
end

function BattleThrowBallEnterFocusPet:GetContactEnterType()
  local speedThreshold = _G.DataConfigManager:GetBattleGlobalConfig("velocity_difference_threshold").num
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local TargetPet = self:GetTargetNPC()
  local contactType
  if localPlayer.IsTurnToTarget and not TargetPet.IsTurnToTarget then
    contactType = BattleEnum.ContactEnterType.PlayerHit
  elseif not localPlayer.IsTurnToTarget and TargetPet.IsTurnToTarget then
    contactType = BattleEnum.ContactEnterType.PetHit
  elseif localPlayer.TouchBattleVel < TargetPet.TouchBattleVel - speedThreshold then
    contactType = BattleEnum.ContactEnterType.PetHit
  elseif localPlayer.TouchBattleVel > TargetPet.TouchBattleVel + speedThreshold then
    contactType = BattleEnum.ContactEnterType.PlayerHit
  else
    contactType = BattleEnum.ContactEnterType.HitTogether
  end
  localPlayer.TouchBattleVel = nil
  TargetPet.TouchBattleVel = nil
  localPlayer.IsTurnToTarget = nil
  TargetPet.IsTurnToTarget = nil
  return contactType
end

function BattleThrowBallEnterFocusPet:LoadSkillOver(skill, Result)
  Log.Debug("BattleThrowBallEnterFocusPet:LoadSkillOver")
  if Result ~= UE4.ESkillStartResult.Success then
    Log.Error("BattleThrowBallEnterFocusPet:LoadSkillOver fail", Result)
    self:releaseFocus()
    return
  end
  if self.skillProxy then
    self.skillObj = self.skillProxy.SkillObject
    if self.cachedValueTable and #self.cachedValueTable > 0 then
      self:ApplyCacheBlackboardValue(self.cachedValueTable, self.skillObj:GetBlackboard())
    end
    if not self.canPlayFocus then
      self.skillProxy:CancelSkill(UE4.ESkillActionResult.SkillActionResultSuccessful)
      self.skillProxy:Destroy()
      self:ReleaseRef()
    end
  end
end

function BattleThrowBallEnterFocusPet:CreateCameraPos()
  self.CameraPos = _G.UE4Helper.GetCurrentWorld():SpawnActor(UE4.AActor, self.npcobj:GetActorTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  self.CameraPos:AddComponentByClass(UE4.USceneComponent, false, UE4.FTransform(), false)
  local aPos = self.npcobj:GetActorLocation()
  local bPos = self.Player:GetActorLocation()
  local dir = bPos - aPos
  dir.Z = 0
  self.CameraPos:Abs_K2_SetActorLocation_WithoutHit(aPos)
  self.CameraPos:K2_SetActorRotation(dir:ToRotator(), true)
end

function BattleThrowBallEnterFocusPet:OnSetCameraMiddle()
  if not self.skillObj then
    Log.Error("BattleThrowBallEnterFocusPet OnSetCameraMiddle no skillObj")
    return
  end
  local Blackboard = self.skillObj:GetBlackboard()
  local KameraSA = Blackboard:GetValueAsObject(BattleConst.BattleStand.CameraID2_SA)
  local Kamera = Blackboard:GetValueAsObject(BattleConst.BattleStand.CameraID2)
  if not KameraSA or not Kamera then
    Log.Error("Camera is nil !!! in BattlePlayBattleStandAnimAction.OnSetCameraMiddle ", BattleConst.BattleStand.CameraID2_SA, BattleConst.BattleStand.CameraID2)
    return
  end
  KameraSA:K2_AttachToActor(self.CameraPos, nil, UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget, false)
  KameraSA:K2_SetActorRelativeLocation(UE4.FVector(200, 0, 75), false, nil, false)
  local aPos = self.npcobj:GetActorLocation()
  local bPos = self.Player:GetActorLocation()
  bPos.Z = math.max(bPos.Z + self.Player:GetScaledHalfHeight() * 1.2, aPos.Z)
  local npcHalfHeight = self.npcobj:GetMeshScaledHalfHeight()
  local scaleValue = 3
  if npcHalfHeight > 100 then
    scaleValue = 1.7
  elseif npcHalfHeight > 60 then
    scaleValue = 2
  end
  local halfPetHeight = npcHalfHeight * scaleValue
  local vectorLength = UE4.UKismetMathLibrary.Vector_Distance(aPos - bPos, UE4.FVector(0, 0, 0))
  local vectorDir = aPos - bPos
  vectorDir:Normalize()
  local screenWidth = math.tan(math.rad(Kamera.CameraComponent.FieldOfView / 2)) * vectorLength
  local screenheight = screenWidth / Kamera.CameraComponent.AspectRatio
  local EndCameraRatio = halfPetHeight / screenheight
  self.EndCameraPos = aPos - vectorDir * vectorLength * EndCameraRatio
  local CheckWaterStart = UE4.FVector(self.EndCameraPos.X, self.EndCameraPos.Y, self.EndCameraPos.Z + 200)
  local hitWaterResult = LineTraceUtils.HitWaterSurface(CheckWaterStart, self.EndCameraPos)
  if hitWaterResult then
    self.EndCameraPos.Z = hitWaterResult.ImpactPoint.Z + 50
  end
  KameraSA:Abs_K2_SetActorLocation_WithoutHit(self.EndCameraPos)
  local cameraPos = KameraSA:Abs_K2_GetActorLocation()
  local dir = aPos - cameraPos
  Kamera:K2_SetActorRotation(dir:ToRotator(), true)
  if self.isBack then
    dir = aPos - bPos
    dir.Z = 0
    self.npcobj:SetActorRotation(dir:ToRotator())
  elseif not BattleUtils.IsBattleAIStatus(self:GetEnemyAIStatus()) then
    dir = bPos - aPos
    dir.Z = 0
    self.npcobj:SetActorRotation(dir:ToRotator())
  end
end

function BattleThrowBallEnterFocusPet:SaveBlackBoardValues()
  local bbValues = {}
  local aiStatus = self:GetEnemyAIStatus()
  if not aiStatus then
    table.insert(bbValues, {"Normal", "True"})
  else
    local isAIStatus, statusString = BattleUtils.IsBattleAIStatus(aiStatus, true)
    if not isAIStatus then
      table.insert(bbValues, {"Normal", "True"})
    else
      local bSetupSleep = BattleThrowBallEnterFocusPet.TrySetupBBValueForSleep(aiStatus, self:GetTargetNPC():GetAnimComponent(), bbValues)
      if bSetupSleep then
      else
        table.insert(bbValues, {statusString, "True"})
      end
    end
  end
  self:SetCacheBlackboardValue(bbValues)
end

function BattleThrowBallEnterFocusPet.TrySetupBBValueForSleep(aiStatus, animComponent, bbValues)
  if aiStatus & 1 << ProtoEnum.BattleAIStatus.BAS_SLEEP > 0 then
    if animComponent and animComponent:IsAnimPlaying("SleepLoop") then
      table.insert(bbValues, {"SleepLoop", "True"})
      _G.BattleManager.EnterSleepAnim = "SleepLoop"
    else
      table.insert(bbValues, {"SleepStand", "True"})
      _G.BattleManager.EnterSleepAnim = "SleepStand"
    end
    return true
  end
  return false
end

function BattleThrowBallEnterFocusPet:GetEnemyAIStatus()
  local resultStatus = 0
  local target = self:GetTargetNPC()
  resultStatus = self.aiStatus
  if target then
    local logicStatusComp = target.LogicStatusComponent
    if logicStatusComp and logicStatusComp.StatusInfo then
      local status_to_add = 0
      for _, status in pairs(logicStatusComp.StatusInfo) do
        local bas_enum = BattleConst.EnterFocusSalsToAiStatusMap[status.status]
        if bas_enum then
          status_to_add = status_to_add | 1 << bas_enum
        end
      end
      if 0 ~= status_to_add then
        Log.Debug("[BattleThrowBallEnterFocusPet] logic status additional aiStatus:", resultStatus)
        resultStatus = resultStatus | status_to_add
      end
    end
  end
  return resultStatus
end

function BattleThrowBallEnterFocusPet:OnSaveCamera()
  if self.skillObj then
    Log.Error("BattleThrowBallEnterFocusPet OnSaveCamera")
    local Blackboard = self.skillObj:GetBlackboard()
    self:SaveObject(Blackboard, BattleConst.BattleStand.CameraID1)
    self:SaveObject(Blackboard, BattleConst.BattleStand.CameraID1_SA)
    self:SaveObject(Blackboard, BattleConst.BattleStand.CameraID2)
    self:SaveObject(Blackboard, BattleConst.BattleStand.CameraID2_SA)
  end
end

function BattleThrowBallEnterFocusPet:SetCacheBlackboardValue(valueTable)
  self.cachedValueTable = valueTable
end

function BattleThrowBallEnterFocusPet:ApplyCacheBlackboardValue(valueTable, blackboard)
  for _, value in ipairs(valueTable) do
    if 2 == #value and type(value[1]) == "string" and nil ~= value[2] then
      blackboard:SetValueAsString(value[1], tostring(value[2]))
    end
  end
end

function BattleThrowBallEnterFocusPet:SaveObject(bb, name)
  Log.Debug("BattlePlayAnimBaseAction SaveObject:", name, bb:GetValueAsObject(name))
  BattleManager:SetProperty(name, bb:GetValueAsObject(name))
  bb:RemoveObjectValue(name)
end

function BattleThrowBallEnterFocusPet:OnPlaySkillEnd()
  Log.Error("BattleThrowBallEnterFocusPet OnPlaySkillEnd")
  self.isFocusing = false
  if self:GetTargetNPC() then
    _G.NRCAudioManager:SetEmitterSwitch("Pet_Switch", "Pet_World", self:GetTargetNPC().viewObj)
  end
end

function BattleThrowBallEnterFocusPet:ReleaseRef()
  Log.Error("BattleThrowBallEnterFocusPet ReleaseRef")
  self.skillProxy = nil
  self.skillObj = nil
  self.npcobj = nil
  self.cachedValueTable = {}
end

function BattleThrowBallEnterFocusPet:OnHidePlayer()
  Log.Debug("BattleThrowBallEnterFocusPet OnHidePlayer")
  NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_ALL, true)
end

function BattleThrowBallEnterFocusPet:OnSkillEvent(event, skill)
  Log.Debug("BattleThrowBallEnterFocusPet OnSkillEvent:", event)
  if self[event] then
    self[event](self, event, skill)
  end
  if "PreEnd" == event then
    self:OnPlaySkillEnd()
  end
end

function BattleThrowBallEnterFocusPet:RevertCam()
end

function BattleThrowBallEnterFocusPet:GetTargetNPC()
  return self.npcobj
end

function BattleThrowBallEnterFocusPet:IsFocusing()
  return self.isFocusing
end

function BattleThrowBallEnterFocusPet:OnTimeoutHandle()
  self:releaseFocus()
  BattleUtils.FocusPlayer()
  NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_ALL, false)
end

function BattleThrowBallEnterFocusPet:OnTick()
  if self:IsFocusing() and self:IsTimeout() then
    self:releaseFocus()
  end
end

return BattleThrowBallEnterFocusPet
