local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleTeamEnterCatchAction = BattleActionBase:Extend("BattleTeamEnterCatchAction")
FsmUtils.MergeMembers(BattleActionBase, BattleTeamEnterCatchAction, {})

function BattleTeamEnterCatchAction:OnEnter()
  self.resList = {
    BattleConst.TeamBloodBeDefeated
  }
  self.loadedResCount = 0
  BattleEventCenter:Bind(self, BattleEvent.OnSkillResLoaded)
  BattleSkillManager:PreLoadRes(self.resList, true)
end

function BattleTeamEnterCatchAction:OnBattleEvent(event, value)
  if event == BattleEvent.OnSkillResLoaded then
    for i = 1, #self.resList do
      if value == self.resList[i] then
        self.loadedResCount = self.loadedResCount + 1
      end
    end
    if self.loadedResCount == #self.resList then
      self:PlaySkill()
    end
    return true
  end
end

function BattleTeamEnterCatchAction:PlaySkill()
  BattleEventCenter:UnBind(self)
  local skillPath = BattleConst.TeamBloodBeDefeated
  local class = BattleSkillManager:GetLoadedClass(skillPath)
  if not class then
    Log.WarningFormat("Can't load skill class %s", skillPath)
    self:SkillFinish()
    return
  end
  self.Boss = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
  if not self.Boss or not self.Boss.model then
    Log.Warning("There is no model in Boss !!!")
    self:SkillFinish()
    return
  end
  self.Boss.IsPerformBeDefeated = true
  local skillComponent = self.Boss.model.RocoSkill
  local skill = skillComponent:FindOrAddSkillObj(class)
  if not skill then
    Log.WarningFormat("Can't find or load skill object %s %s", class, skillPath)
    self:SkillFinish()
    return
  end
  BattleManager.battlePawnManager:TogglePetBuffsVisibility(false)
  local characters = BattleManager.battlePawnManager:GetAllPawnActorForSkill()
  local blackBoard = skill:GetBlackboard()
  if blackBoard then
    local key = tostring(BattleConst.BloodType2AttrType[self.Boss.card.petInfo.battle_common_pet_info.blood_id])
    blackBoard:SetValueAsString(key, key)
  end
  skill:SetPassive(true)
  skill:SetCaster(self.Boss.model)
  skill:SetTargets({
    self.Boss.model
  })
  skill:SetCharacters(characters)
  skill:RegisterEventCallback("BossStun", self, self.BossStun)
  skill:RegisterEventCallback("PreEnd", self, self.SkillFinish)
  skill:RegisterEventCallback("End", self, self.SkillFinish)
  skillComponent:PlaySkill(skill)
end

function BattleTeamEnterCatchAction:BossStun()
  if self.Boss then
    self.Boss.buffComponent:PlayStateEffect(Enum.BuffGroupSign.BGS_CATCHSTUN)
    self.Boss.card.petState:SetCatchStun(true)
  end
end

function BattleTeamEnterCatchAction:SkillFinish()
  if not self.finished then
    self.Boss = nil
    self:Finish()
  end
end

function BattleTeamEnterCatchAction:OnFinish()
  _G.BattleEventCenter:Dispatch(BattleEvent.TEAM_BATTLE_CATCH)
  self.fsm:SendEvent(BattleEvent.EnterRoundSelect, self)
end

return BattleTeamEnterCatchAction
