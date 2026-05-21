local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local BattleTeamBeastDefeatAction = BattleActionBase:Extend("BattleTeamBeastDefeatAction")
FsmUtils.MergeMembers(BattleActionBase, BattleTeamBeastDefeatAction, {})

function BattleTeamBeastDefeatAction:OnEnter()
  self:RevertPetsPosition()
  self:PrepareBoss()
  if self.Boss and not BattleUtils.IsBossPerformDegrade() then
    BattleEventCenter:Bind(self, BattleEvent.OnSkillResLoaded, BattleEvent.PET_SPAWNED)
    self:PreLoadG6Res()
    self:PawnNewPet()
  else
    self:SkillFinish()
  end
end

function BattleTeamBeastDefeatAction:RevertPetsPosition()
  if not BattleManager:IsInBattle() then
    return
  end
  local AllPets = BattleManager.battlePawnManager:GetAllPets()
  for _, pet in pairs(AllPets) do
    if pet.card:IsCanSelect() then
      local RightPosTransForm = BattleManager.battlePawnManager.VBattleField:GetPositionInBattleMap(pet.teamEnm, pet.card.posInField)
      if RightPosTransForm then
        local RightPos = RightPosTransForm.Translation
        local NowPos = pet:GetActorLocation()
        if NowPos then
          if NowPos:Dist(RightPos) >= 500 then
            RightPos.Z = RightPos.Z + pet:GetHalfHeight()
            pet.model:K2_SetActorLocation(SceneUtils.ConvertAbsoluteToRelative(RightPos), false, nil, false)
            pet:PinOnTheGround()
          end
        else
          Log.Error("zgx pet is no location")
        end
      end
    end
  end
end

function BattleTeamBeastDefeatAction:PrepareBoss()
  self.Boss = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
  self.Boss.card:ClearBuffs()
  self.Boss.card.petInfo.battle_inside_pet_info.kill_info = nil
end

function BattleTeamBeastDefeatAction:PreLoadG6Res()
  local skillPath = BattleManager.battleRuntimeData.battleConfig and BattleManager.battleRuntimeData.battleConfig.die_show or BattleConst.TeamBeastBeDefeated
  self.resList = {skillPath}
  self.loadedResCount = 0
  BattleSkillManager:PreLoadRes(self.resList, true)
end

function BattleTeamBeastDefeatAction:PawnNewPet()
  BattleManager.battlePawnManager:PawnPet(self.Boss.teamEnm, self.Boss.team, self.Boss.card, self.Boss.player, false, true)
end

function BattleTeamBeastDefeatAction:OnBattleEvent(event, value)
  if event == BattleEvent.OnSkillResLoaded then
    for i = 1, #self.resList do
      if value == self.resList[i] then
        self.loadedResCount = self.loadedResCount + 1
      end
    end
    if self.loadedResCount == #self.resList then
      self:CheckCanPlaySkill()
    end
    return true
  elseif event == BattleEvent.PET_SPAWNED then
    self:SpawnPetFinish(value)
    return true
  end
end

function BattleTeamBeastDefeatAction:SpawnPetFinish(pet)
  if self.Boss and pet then
    self.OldBoss = self.Boss
    self.Boss = pet
    self.Boss:HidePet()
    self.Boss.buffComponent:RemoveBuffs(true)
    self.Boss.buffComponent:ClearBuff()
    UE.UNRCCharacterUtils.SetCharacterMeshScale(self.Boss.model, self.Boss.card.initResourceScale)
    self:CheckCanPlaySkill()
  else
    self:Finish()
  end
end

function BattleTeamBeastDefeatAction:CheckCanPlaySkill()
  if self.loadedResCount < #self.resList then
    return
  end
  if not self.OldBoss then
    return
  end
  self:PlaySkill()
end

function BattleTeamBeastDefeatAction:PlaySkill()
  BattleEventCenter:UnBind(self)
  if not self.Boss or not self.Boss.model then
    Log.Warning("There is no model in Boss !!!")
    self:SkillFinish()
    return
  end
  if not self.OldBoss or not self.OldBoss.model then
    Log.Warning("There is no model in OldBoss !!!")
    self:SkillFinish()
    return
  end
  self.Boss.IsPerformBeDefeated = true
  local skillComponent = self.Boss.model.RocoSkill
  if not skillComponent then
    Log.Warning("There is no RocoSkill in Boss !!!")
    self:SkillFinish()
    return
  end
  BattleManager.battlePawnManager:TogglePetBuffsVisibility(false)
  local MyCastObject = CastSkillObject.FromSkillResID(self.resList[1])
  if MyCastObject then
    MyCastObject:SetCallbackOwner(self)
    MyCastObject:SetCaster(self.OldBoss.model)
    MyCastObject:SetInterrupt(true)
    MyCastObject:SetTargetPets({
      self.Boss
    })
    MyCastObject:SetCharacters(BattleManager.battlePawnManager:GetAllPawnActorForSkill())
    MyCastObject:SetCompleteCallback(self.SkillFinish)
    MyCastObject:SetExtraEvents({
      ActionStart = self.ShowPet,
      StunBuff = self.StunBuff
    })
    local _, skill = BattleSkillManager:PrepareSkill(self.Boss, skillComponent, MyCastObject)
    if not skill then
      Log.WarningFormat("Can't find or load skill object %s %s", MyCastObject.ResID)
      self:SkillFinish()
      return
    end
    skillComponent:PlaySkill(skill)
  else
    Log.Error("zgx res is vaild!!", BattleConst.TeamBeastBeDefeated)
    self:SkillFinish()
  end
end

function BattleTeamBeastDefeatAction:ShowPet()
  if self.Boss then
    self.Boss:ShowPet(false)
    self.Boss.buffComponent:RemoveBuffs(true)
    self.Boss.buffComponent:ClearBuff()
  end
end

function BattleTeamBeastDefeatAction:StunBuff()
  if self.Boss then
    self.Boss.buffComponent:PlayStateEffect(Enum.BuffGroupSign.BGS_CATCHSTUN)
    self.Boss.card.petState:SetCatchStun(true)
  end
end

function BattleTeamBeastDefeatAction:SkillFinish()
  if not self.finished then
    if self.OldBoss then
      if self.Boss then
        self.Boss.model:K2_DetachFromActor(UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld)
      end
      self.OldBoss:OnRecall()
      self.OldBoss = nil
    end
    if self.Boss then
      if not self.Boss.buffComponent:CheckStateIsPlaying(Enum.BuffGroupSign.BGS_CATCHSTUN) then
        self:StunBuff()
      end
      self.Boss:PinOnTheGround()
    end
    self.Boss = nil
    self:RevertPetsPosition()
    if BattleManager.vBattleField.battleCraneCamera then
      BattleUtils.UnLockCam()
      BattleManager.vBattleField.battleCameraManager:CalcPosCache()
      BattleManager.vBattleField.battleCraneCamera:ChangeToPlayerCatch(1, true, nil, nil, true)
    end
    self:Finish()
  end
end

function BattleTeamBeastDefeatAction:OnFinish()
  if self.OldBoss then
    self.OldBoss:OnRecall()
    self.OldBoss = nil
  end
end

return BattleTeamBeastDefeatAction
