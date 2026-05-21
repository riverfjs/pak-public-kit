local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local Enum = require("Data.Config.Enum")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local BattleTeamBeastEnterCatchAction = BattleActionBase:Extend("BattleTeamBeastEnterCatchAction")
FsmUtils.MergeMembers(BattleActionBase, BattleTeamBeastEnterCatchAction, {})

function BattleTeamBeastEnterCatchAction:OnEnter()
  if not BattleUtils.IsBossPerformSpColor() then
    self.Boss = _G.BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
    self.Boss.IsPerformSpColor = true
    local data = NRCModuleManager:DoCmd(LegendaryBattleModuleCmd.GetCatchConfirmRsp)
    if data then
      self.boss_data = data.boss_data
      if data.boss_shiny and data.boss_shiny > 0 then
        self.boss_shiny = data.boss_shiny
      else
        self.boss_shiny = nil
      end
      self.resList = {
        BattleConst.TeamBeastDegrade
      }
      self.Boss.card:RefreshByBaseConf(data.degenerated_boss_base_id)
      self.Boss.card:InternalOverwriteByServer({
        battle_common_pet_info = data.boss_data
      })
      self.Boss.card:RefreshByServerPetData()
      self.Boss.card:ClearBuffs()
      self.Boss.card.petInfo.battle_inside_pet_info.kill_info = nil
      self.loadedResCount = 0
      BattleEventCenter:Bind(self, BattleEvent.OnSkillResLoaded, BattleEvent.PET_SPAWNED)
      BattleSkillManager:PreLoadRes(self.resList, true)
    else
      self:Finish()
    end
  else
    self:Finish()
  end
end

function BattleTeamBeastEnterCatchAction:OnBattleEvent(event, value)
  if event == BattleEvent.OnSkillResLoaded then
    for i = 1, #self.resList do
      if value == self.resList[i] then
        self.loadedResCount = self.loadedResCount + 1
      end
    end
    if self.loadedResCount == #self.resList then
      self:SpawnDegeneratedBoss()
    end
    return true
  elseif event == BattleEvent.PET_SPAWNED then
    _G.BattleManager.vBattleField.battleCameraManager:CalcPosCache()
    self:SpawnPetFinish(value)
    return true
  end
end

function BattleTeamBeastEnterCatchAction:SpawnDegeneratedBoss()
  if self.Boss then
    BattleManager.battlePawnManager:PawnPet(self.Boss.teamEnm, self.Boss.team, self.Boss.card, self.Boss.player, false, true)
  else
    self:Finish()
  end
end

function BattleTeamBeastEnterCatchAction:SpawnPetFinish(pet)
  if self.Boss and pet then
    self.OldBoss = self.Boss
    self.Boss = pet
    self.Boss.IsPerformSpColor = true
    self.Boss:HidePet()
    self.Boss.buffComponent:RemoveBuffs(true)
    self.Boss.buffComponent:ClearBuff()
    self:PlaySkill()
  else
    self:Finish()
  end
end

function BattleTeamBeastEnterCatchAction:PlaySkill()
  BattleEventCenter:UnBind(self)
  if not self.Boss or not self.Boss.model then
    Log.Warning("There is no model in Boss !!!")
    self:SkillFinish()
    return
  end
  local skillComponent = self.Boss.model.RocoSkill
  if not skillComponent then
    Log.Warning("There is no RocoSkill in Boss !!!")
    self:SkillFinish()
    return
  end
  BattleManager.battlePawnManager:TogglePetBuffsVisibility(false)
  local MyCastObject = CastSkillObject.FromSkillResID(self.resList[1])
  if MyCastObject then
    MyCastObject:SetIsPassive(true)
    MyCastObject:SetCallbackOwner(self)
    MyCastObject:SetCaster(self.OldBoss.model)
    MyCastObject:SetTargetPets({
      self.Boss
    })
    MyCastObject:SetCompleteCallback(self.SkillFinish)
    MyCastObject:SetExtraEvents({
      ChangeState = self.ChangeState,
      ChangePetModel = self.ChangePetModel
    })
    local _, skill = BattleSkillManager:PrepareSkill(self.Boss, skillComponent, MyCastObject)
    if not skill then
      Log.WarningFormat("Can't find or load skill object %s %s", MyCastObject.ResID)
      self:SkillFinish()
      return
    end
    skillComponent:PlaySkill(skill)
  else
    Log.Error("zgx res is vaild!!", self.resList[1])
    self:SkillFinish()
  end
end

function BattleTeamBeastEnterCatchAction:ChangePetModel()
  if self.Boss and self.OldBoss then
    self.Boss:ShowPet()
    self.OldBoss:OnRecall()
  end
end

function BattleTeamBeastEnterCatchAction:ChangeState()
  if self.Boss and self.Boss.model then
    PetMutationUtils.DoMutation(self.Boss.model, self.boss_data)
  end
end

function BattleTeamBeastEnterCatchAction:SkillFinish(name, skill)
  if not self.finished then
    skill:SetPlayRate(0)
    self.Boss.buffComponent:PlayStateEffect(Enum.BuffGroupSign.BGS_CATCHSTUN)
    self.Boss.card.petState:SetCatchStun(true)
    self.Boss = nil
    self.OldBoss = nil
    self:Finish()
  end
end

function BattleTeamBeastEnterCatchAction:OnFinish()
  NRCModeManager:DoCmd(BattleUIModuleCmd.CloseTransformLoadingUI)
  _G.BattleEventCenter:Dispatch(BattleEvent.TEAM_BATTLE_CATCH)
  self.fsm:SendEvent(BattleEvent.EnterRoundSelect, self)
end

return BattleTeamBeastEnterCatchAction
