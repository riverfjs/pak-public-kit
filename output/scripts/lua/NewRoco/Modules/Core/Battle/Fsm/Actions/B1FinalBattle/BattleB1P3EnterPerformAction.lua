local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local Base = BattleActionBase
local BattleB1P3EnterPerformAction = Base:Extend("BattleB1P3EnterPerformAction")
FsmUtils.MergeMembers(Base, BattleB1P3EnterPerformAction, {})

function BattleB1P3EnterPerformAction:OnEnter()
  self.BattleManager = _G.BattleManager
  _G.NRCModeManager:DoCmd(_G.B1FinalBattleModuleCmd.SetFirstEnterP2Battle, true)
  local mainWindow = _G.BattleUtils.GetMainWindow()
  if mainWindow then
    mainWindow:RefreshOperatePanel()
  end
  self.PawnManger = self.BattleManager.battlePawnManager
  local BossPets = self.PawnManger:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY, true)
  if BossPets and BossPets[1] then
    local skillPath = BattleConst.B1P3EnterG6
    local class = BattleSkillManager:GetLoadedClass(skillPath)
    if not class then
      Log.WarningFormat("Can't load skill class %s", skillPath)
      self:Finish()
      return
    end
    local skillComponent = BossPets[1].model.RocoSkill
    local skill = skillComponent:FindOrAddSkillObj(class)
    if not skill then
      Log.WarningFormat("Can't find or load skill object %s %s", class, skillPath)
      self:Finish()
      return
    end
    skill:SetCaster(BossPets[1].model)
    skill:SetTargets({
      BossPets[1].model
    })
    skill:SetPassive(true)
    skill:SetCharacters(_G.BattleManager.battlePawnManager:GetAllPawnActorForSkill())
    skill:RegisterEventCallback("End", self, self.Finish)
    skill:RegisterEventCallback("PreEnd", self, self.Finish)
    skill:RegisterEventCallback("ActionStart", self, self.OnActionStart)
    skillComponent:LoadAndPlaySkill(skill)
  else
    self:Finish()
  end
end

function BattleB1P3EnterPerformAction:OnActionStart()
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.CLOSE_BLACK_SCREEN)
  BattleManager:PlayBattleBGM()
end

function BattleB1P3EnterPerformAction:OnFinish()
  _G.BattleEventCenter:Dispatch(BattleEvent.SHOW_TEAMBATTLE_HP)
end

return BattleB1P3EnterPerformAction
