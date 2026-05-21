local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local BattleCraneCameraDefine = require("NewRoco.Modules.Core.Battle.CraneCamera.BattleCraneCameraDefine")
local BattleAIStandManager = NRCClass()
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")

function BattleAIStandManager:Ctor()
  self.BattleManager = _G.BattleManager
  self.PawnManager = self.BattleManager.battlePawnManager
  self.originPosCache = nil
  self.leftPosCache = nil
  self.hasLeftPos = false
end

function BattleAIStandManager:GetStandState(battlePet)
  if not battlePet or not battlePet.model then
    return BattleCraneCameraDefine.PetStandState.None
  end
  local curPos = battlePet.model:K2_GetActorLocation()
  if not curPos then
    return BattleCraneCameraDefine.PetStandState.None
  end
  local halfHeight = battlePet.model:GetHalfHeight()
  curPos.Z = curPos.Z - halfHeight
  local RightPos = self:GetOriginPos(battlePet)
  if not RightPos then
    return BattleCraneCameraDefine.PetStandState.None
  end
  local dist = curPos:Dist2D(RightPos)
  if dist <= 10 then
    return BattleCraneCameraDefine.PetStandState.Origin
  else
    return BattleCraneCameraDefine.PetStandState.Left
  end
end

function BattleAIStandManager:JumpToLeft(pet)
  local pos = self:GetLeftPos(pet)
  if pos then
    return BattleAIManager:JumpToPosFixed(pet, pos)
  end
  return false
end

function BattleAIStandManager:JumpToOrigin(pet)
  local pos = self:GetOriginPos(pet)
  if pos then
    return BattleAIManager:JumpToPosFixed(pet, pos)
  end
  return false
end

function BattleAIStandManager:GetOriginPos(pet)
  if not self.PawnManager.VBattleField then
    return nil
  end
  local RightPosTransForm = self.PawnManager.VBattleField:GetPositionInBattleMap(pet.teamEnm, pet.card.posInField)
  if RightPosTransForm then
    local RightPos = RightPosTransForm.Translation
    self.originPosCache = UE4.UNRCStatics.PinActorOnGround(nil, pet.model, SceneUtils.ConvertAbsoluteToRelative(RightPos), pet.model)
  end
  return self.originPosCache
end

function BattleAIStandManager:GetLeftPos(pet)
  if not self.hasLeftPos then
    local oriPos = self:GetOriginPos(pet)
    if not oriPos then
      return
    end
    local leftDir = -UE4.UKismetMathLibrary.GetRightVector(pet.model:K2_GetActorRotation())
    local leftLoc = oriPos + leftDir * 200
    local groundPos, isHit = LineTraceUtils.GetPointValidLocationByLine(leftLoc, 1000, false)
    local nav_point, nav_result = UE4.UNavigationSystemV1.K2_ProjectPointToNavigation(UE4Helper.GetCurrentWorld(), groundPos)
    if not nav_result then
      return nil
    end
    local dist = math.abs(groundPos.Z - leftLoc.Z)
    if dist <= 50 then
      self.leftPosCache = groundPos
    end
    self.hasLeftPos = true
  end
  return self.leftPosCache
end

function BattleAIStandManager:JumpOver()
  if self.jumpCaller and self.jumpCallBack then
    self.jumpCallBack(self.jumpCaller)
  end
  self.jumpCaller = nil
  self.jumpCallBack = nil
end

function BattleAIStandManager:CheckOver()
  self.Jumping = false
  if self.checkCaller and self.checkCallBack then
    self.checkCallBack(self.checkCaller)
  end
  self.checkCaller = nil
  self.checkCallBack = nil
end

function BattleAIStandManager:CheckJumpAnim(Caller, CallBack)
  self.checkCaller = Caller
  self.checkCallBack = CallBack
  if not _G.BattleManager.isInBattle then
    self:CheckOver()
    return
  end
  if BattleUtils.IsDeepWater() then
    self:CheckOver()
    return
  end
  local battleConfig = _G.BattleManager.battleRuntimeData and _G.BattleManager.battleRuntimeData.battleConfig or nil
  if battleConfig and 1 ~= battleConfig.challanger_unit_num then
    self:CheckOver()
    return
  end
  if not _G.BattleManager.battlePawnManager.playerTeam then
    self:CheckOver()
    return
  end
  local teamPlayer = _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
  if not (teamPlayer and teamPlayer.model) or not UE4.UObject.IsValid(teamPlayer.model) then
    self:CheckOver()
    return
  end
  local skillComponent = teamPlayer.model.RocoSkill
  if not skillComponent or not UE4.UObject.IsValid(skillComponent) then
    self:CheckOver()
    return
  end
  local activeSkill = skillComponent:GetActiveSkill()
  if activeSkill then
    self:CheckOver()
    return
  end
  local battlePet = BattleManager.battlePawnManager:GetFirstPet(BattleEnum.Team.ENUM_TEAM)
  if not battlePet then
    self:CheckOver()
    return
  end
  local curCameraTg = _G.BattleManager.vBattleField.battleCraneCamera.confData:GetCurCameraTag()
  if not curCameraTg then
    self:CheckOver()
    return
  end
  if self.Jumping then
    self:CheckOver()
    return
  end
  local standState = self:GetStandState(battlePet)
  if standState == BattleCraneCameraDefine.PetStandState.None then
    self:CheckOver()
    self.Jumping = false
    return
  end
  if curCameraTg == UE4.EBattleCameraTags.PlayerCatch then
    if standState == BattleCraneCameraDefine.PetStandState.Origin then
      self.Jumping = true
      local isSuccess = self:JumpToLeft(battlePet)
      if not isSuccess then
        self:CheckOver()
        self.Jumping = false
      end
    end
  elseif standState == BattleCraneCameraDefine.PetStandState.Left then
    self.Jumping = true
    local isSuccess = self:JumpToOrigin(battlePet)
    if not isSuccess then
      self:CheckOver()
      self.Jumping = false
    end
  end
end

function BattleAIStandManager:JumpToOriginForce(Caller, CallBack)
  self.jumpCaller = Caller
  self.jumpCallBack = CallBack
  if BattleUtils.IsDeepWater() then
    self:JumpOver()
    return
  end
  local battleConfig = _G.BattleManager.battleRuntimeData and _G.BattleManager.battleRuntimeData.battleConfig or nil
  if battleConfig and 1 ~= battleConfig.challanger_unit_num then
    self:JumpOver()
    return
  end
  if not _G.BattleManager.battlePawnManager.playerTeam then
    self:JumpOver()
    return
  end
  local battlePet = _G.BattleManager.battlePawnManager:GetFirstPet(BattleEnum.Team.ENUM_TEAM)
  if not battlePet then
    self:JumpOver()
    return
  end
  local standState = self:GetStandState(battlePet)
  if standState == BattleCraneCameraDefine.PetStandState.Left then
    local OriginPos = self:GetOriginPos(battlePet)
    battlePet:JumpToLocation(OriginPos, self, self.JumpOver)
  else
    self:JumpOver()
  end
end

return BattleAIStandManager
