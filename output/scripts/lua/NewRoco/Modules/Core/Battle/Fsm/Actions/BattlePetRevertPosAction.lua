local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local Base = BattleActionBase
local BattlePetRevertPosAction = Base:Extend("BattlePetRevertPosAction")
FsmUtils.MergeMembers(Base, BattlePetRevertPosAction, {})

function BattlePetRevertPosAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.BattleManager = _G.BattleManager
  self.PawnManager = self.BattleManager.battlePawnManager
end

function BattlePetRevertPosAction:OnEnter()
  if not self:CheckBattleNoOver() then
    self:Finish()
    return
  end
  if self:CheckIsInCatchCamera() then
    self:Finish()
    return
  end
  self.JumpingPetsNum = 0
  local AllPets = self.PawnManager:GetAllPets()
  for _, pet in pairs(AllPets) do
    if pet.model and pet.card:IsCanSelect() then
      local RightPosTransForm = self.PawnManager.VBattleField:GetPositionInBattleMap(pet.teamEnm, pet.card.posInField)
      if RightPosTransForm then
        local RightPos = RightPosTransForm.Translation
        local NowPos = pet:GetActorLocation()
        if NowPos then
          if pet.model.GetCurrentHalfHeight then
            RightPos.Z = RightPos.Z + pet.model:GetCurrentHalfHeight()
          else
            RightPos.Z = NowPos.Z
          end
          if NowPos:Dist(RightPos) >= 70 then
            RightPos = UE4.UNRCStatics.PinActorOnGround(nil, pet.model, SceneUtils.ConvertAbsoluteToRelative(RightPos), pet.model)
            NowPos = SceneUtils.ConvertAbsoluteToRelative(NowPos)
            if NowPos:Dist(RightPos) >= 70 then
              self.JumpingPetsNum = self.JumpingPetsNum + 1
              pet:JumpToLocation(RightPos, self, self.JumpOver)
            end
          else
            pet:PinOnTheGround()
          end
        else
          Log.Error("zgx pet is no location")
        end
      end
      if not _G.BattleManager.battleRuntimeData.battleDebugControl or not _G.BattleManager.battleRuntimeData.battleDebugControl.isInAutoTest then
        pet:SetPetVisibility(true)
      end
    end
  end
  if 0 == self.JumpingPetsNum then
    self:Finish()
  end
end

function BattlePetRevertPosAction:CheckIsInCatchCamera()
  local IsFromInstantBattleFsm = self.fsm:GetProperty("IsFromInstantBattleFsm")
  if IsFromInstantBattleFsm and _G.BattleManager.vBattleField and _G.BattleManager.vBattleField.battleCraneCamera then
    local curCameraTg = _G.BattleManager.vBattleField.battleCraneCamera.confData:GetCurCameraTag()
    if curCameraTg and curCameraTg == UE4.EBattleCameraTags.PlayerCatch then
      return true
    end
  end
  return false
end

function BattlePetRevertPosAction:CheckBattleNoOver()
  local hasTeamPet = false
  local teamPets = self.PawnManager:GetTeamAllPets()
  for i, v in pairs(teamPets) do
    if v.model and v.card:IsCanSelect() then
      hasTeamPet = true
    end
  end
  local hasEnemyPet = false
  local enemyPets = self.PawnManager:GetEnemyAllPets()
  for i, v in pairs(enemyPets) do
    if v.model and v.card:IsCanSelect() then
      hasEnemyPet = true
    end
  end
  return hasTeamPet and hasEnemyPet
end

function BattlePetRevertPosAction:JumpOver()
  if self.JumpingPetsNum > 0 then
    self.JumpingPetsNum = self.JumpingPetsNum - 1
    if 0 == self.JumpingPetsNum then
      self:Finish()
    end
  end
end

return BattlePetRevertPosAction
