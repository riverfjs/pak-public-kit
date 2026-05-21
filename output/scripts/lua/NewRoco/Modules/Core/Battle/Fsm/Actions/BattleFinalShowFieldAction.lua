local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleFinalShowFieldAction = BattleActionBase:Extend("BattleLeaderBattleShowTime")

function BattleFinalShowFieldAction:OnEnter()
  self:SetActionType(BattleActionBase.ActionType.ClientTurnPlayAction)
  self.Caster = BattleManager.battlePawnManager.TeamatePlayer
  self.Target = BattleManager.battlePawnManager:GetFirstPet(BattleEnum.Team.ENUM_ENEMY)
  self.skillResList = {
    BattleConst.FinalBattleP1ToP2G6
  }
  self.loadedSkillResCount = 0
  _G.BattleEventCenter:Bind(self, BattleEvent.OnSkillResLoaded)
  _G.BattleSkillManager:PreLoadRes(self.skillResList, true)
end

function BattleFinalShowFieldAction:OnBattleEvent(event, value)
  if event == BattleEvent.OnSkillResLoaded then
    for i = 1, #self.skillResList do
      if value == self.skillResList[i] then
        self.loadedSkillResCount = self.loadedSkillResCount + 1
      end
    end
    if self.loadedSkillResCount == #self.skillResList then
      self:PlaySkill()
    end
  end
end

function BattleFinalShowFieldAction:PlaySkill()
  if not self.Caster or not self.Caster.model then
    self:Finish()
    return
  end
  local skillComponent = self.Caster.model.RocoSkill
  if not skillComponent then
    self:Finish()
    return
  end
  local skillPath = self.skillResList[1]
  local skillClass = BattleSkillManager:GetLoadedClass(skillPath)
  if not skillClass then
    Log.ErrorFormat("Failed to load skill class %s", skillPath)
    self:Finish()
    return
  end
  local skillObj = skillComponent:FindOrAddSkillObj(skillClass)
  if not skillObj then
    self:Finish()
    return
  end
  skillObj:SetCaster(self.Caster.model)
  skillObj:SetTargets({
    self.Caster.model
  })
  skillObj:SetCharacters(_G.BattleManager.battlePawnManager:GetAllPawnActorForSkill())
  skillObj:SetPassive(true)
  skillObj:RegisterEventCallback("Start", self, self.CloseLoading)
  skillObj:RegisterEventCallback("End", self, self.OnSkillEnd)
  skillObj:RegisterEventCallback("PreEnd", self, self.OnSkillEnd)
  skillObj:RegisterEventCallback("Interrupt", self, self.OnSkillEnd)
  skillObj:RegisterEventCallback("StartFailed", self, self.OnSkillEnd)
  skillComponent:PlaySkill(skillObj)
end

function BattleFinalShowFieldAction:CloseLoading(Event, Skill)
  if self.Target then
    self.Target:SetScale(1)
    self.Target:ShowPet()
  end
  if self.Caster then
    self.Caster:ShowPlayer()
    local sceneComp = self.Caster.model:GetComponentByClass(UE4.USceneComponent)
    if sceneComp then
      sceneComp:SetVisibility(true)
    end
  end
  if BattleManager.CacheSequencer then
    self:SafeDelayFrames("d_CacheSequencer", 2, function()
      NRCModeManager:DoCmd(BattleUIModuleCmd.CloseTransformLoadingUI)
      if BattleManager.CacheSequencer then
        BattleManager.CacheSequencer = nil
        if not self.finished and Skill then
          local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
          local playerController = localPlayer:GetUEController()
          local cam = Skill:GetBlackboard():GetValueAsObject("camActor_0001")
          playerController:SetViewTargetWithBlend(cam, 0)
        end
      end
    end)
  end
end

function BattleFinalShowFieldAction:SaveBlackboard(blackboard, name)
  FsmUtils.SaveAsProperty(self.fsm, blackboard, name)
end

function BattleFinalShowFieldAction:OnSkillEnd(Event, Skill)
  local Blackboard = Skill:GetBlackboard()
  self:SaveBlackboard(Blackboard, "camActor_0001")
  self:SaveBlackboard(Blackboard, "camActor_0001_SA")
  self:Finish()
end

function BattleFinalShowFieldAction:OnFinish()
  self.Caster = nil
  self.Target = nil
  self:CloseLoading()
  _G.BattleEventCenter:UnBind(self)
end

return BattleFinalShowFieldAction
