local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local BattleTeamBeastBeStun = BattleActionBase:Extend("BattleTeamBeastBeStun")
FsmUtils.MergeMembers(BattleActionBase, BattleTeamBeastBeStun, {})

function BattleTeamBeastBeStun:OnEnter()
  self:HidePlayerAndPets()
  if not BattleUtils.IsBossPerformBeDefeated() then
    self.resList = {
      BattleConst.TeamBeastBeStun
    }
    self.loadedResCount = 0
    BattleEventCenter:Bind(self, BattleEvent.OnSkillResLoaded)
    BattleSkillManager:PreLoadRes(self.resList, true)
  else
    self:Finish()
  end
end

function BattleTeamBeastBeStun:HidePlayerAndPets()
  local teams = BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_TEAM)
  for i, team in pairs(teams) do
    if team.player and team.player ~= BattleManager.battlePawnManager.TeamatePlayer then
      team.player:Hide()
      for _, pet in pairs(team.pets) do
        pet:HidePet()
      end
    end
  end
end

function BattleTeamBeastBeStun:OnBattleEvent(event, value)
  if event == BattleEvent.OnSkillResLoaded then
    for i = 1, #self.resList do
      if value == self.resList[i] then
        self.loadedResCount = self.loadedResCount + 1
      end
    end
    if self.loadedResCount == #self.resList then
      self:PlaySkill()
    end
  end
end

function BattleTeamBeastBeStun:PlaySkill()
  BattleEventCenter:UnBind(self)
  self.Boss = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
  if not self.Boss or not self.Boss.model then
    Log.Warning("There is no model in Boss !!!")
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
  local MyCastObject = CastSkillObject.FromSkillResID(BattleConst.TeamBeastBeStun)
  if MyCastObject then
    MyCastObject:SetIsPassive(true)
    MyCastObject:SetCallbackOwner(self)
    MyCastObject:SetCaster(self.Boss.model)
    MyCastObject:SetTargetPets({
      self.Boss
    })
    MyCastObject:SetCharacters(BattleManager.battlePawnManager:GetAllPawnActorForSkill())
    MyCastObject:SetCompleteCallback(self.SkillFinish)
    local _, skill = BattleSkillManager:PrepareSkill(self.Boss, skillComponent, MyCastObject)
    if not skill then
      Log.WarningFormat("Can't find or load skill object %s %s", MyCastObject.ResID)
      self:SkillFinish()
      return
    end
    skillComponent:PlaySkill(skill)
  else
    Log.Error("zgx res is vaild!!", BattleConst.TeamBeastBeStun)
    self:SkillFinish()
  end
end

function BattleTeamBeastBeStun:SkillFinish()
  if not self.finished then
    if self.Boss then
      self.Boss.card.petState:SetCatchStun(true)
    end
    self.Boss = nil
    self:Finish()
  end
end

return BattleTeamBeastBeStun
