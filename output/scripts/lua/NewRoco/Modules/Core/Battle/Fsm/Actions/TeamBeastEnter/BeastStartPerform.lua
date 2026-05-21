local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local Base = BattleActionBase
local BeastBeforeBattlePerform = Base:Extend("BeastBeforeBattlePerform")
FsmUtils.MergeMembers(Base, BeastBeforeBattlePerform, {})

function BeastBeforeBattlePerform:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self:SetActionType(Base.ActionType.ClientTurnPlayAction)
end

function BeastBeforeBattlePerform:OnEnter()
  local skillPath = self.fsm:GetProperty("BeastStartSkill")
  if not skillPath then
    self:Finish()
  end
  self.fsm:SetProperty("BeastStartSkill", nil)
  BattleEventCenter:Bind(self, BattleEvent.TransformLoadingOpened)
  self:PlaySKill(skillPath)
end

function BeastBeforeBattlePerform:PlaySKill(skillPath)
  _G.NRCModuleManager:DoCmd(LegendaryBattleModuleCmd.OnEnterBattleLoading)
  NRCModeManager:GetCurMode():DisablePanelByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer or not localPlayer.viewObj then
    Log.Warning("There is no model in localPlayer !!!")
    self:Finish()
    return
  end
  local BeastBoss = BattleUtils.GetTraceNpc()
  if not (BeastBoss and BeastBoss.npc) or not BeastBoss.npc.viewObj then
    Log.Warning("There is no model in Target !!!")
    BeastBoss = localPlayer
  elseif skillPath == BattleConst.TeamPerEnterFarBattle then
    BeastBoss = localPlayer
  else
    BeastBoss = BeastBoss.npc
  end
  local skillComponent = localPlayer.viewObj.RocoSkill
  if not skillComponent then
    Log.Warning("There is no skillComponent")
    self:Finish()
    return
  end
  local MyCastObject = CastSkillObject.FromSkillResID(skillPath)
  if MyCastObject then
    local battleConf = BattleUtils.GetBattleConfig()
    MyCastObject:SetCallbackOwner(self)
    MyCastObject:SetCaster(BeastBoss.viewObj)
    MyCastObject:SetIsPassive(true)
    MyCastObject:SetCharacters({})
    MyCastObject:SetCompleteCallback(self.SkillFinish)
    MyCastObject:SetExtraEvents({
      SaveCamera = self.SaveCamera
    })
    if battleConf and not string.IsNilOrEmpty(battleConf.transiton_blackboard) then
      MyCastObject:AddBlackStringValue(battleConf.transiton_blackboard, battleConf.transiton_blackboard)
    end
    self.skillComponent = skillComponent
    self:PlaySkill(localPlayer, skillComponent, MyCastObject)
  else
    Log.Error("zgx res is vaild!!", skillPath)
    self:Finish()
  end
end

function BeastBeforeBattlePerform:PlaySkill(battlePet, skillComponent, skillObject, isNotPlay)
  local _, skill = BattleSkillManager:PrepareSkill(battlePet, skillComponent, skillObject)
  if not skill then
    Log.WarningFormat("Can't find or load skill object %s %s", skillObject.ResID)
    self:Finish()
    return
  end
  if not isNotPlay then
    skillComponent:PlaySkill(skill)
  end
  return skill
end

function BeastBeforeBattlePerform:SaveCamera(name, skill)
  if self.finished then
    return
  end
  if skill then
    local blackboard = skill:GetBlackboard()
    if blackboard then
      self:SaveBlackboard(blackboard, "camActor_0001")
      self:SaveBlackboard(blackboard, "camActor_0001_SA")
      local camera = self.fsm:GetProperty("camActor_0001")
      self.fsm:SetProperty("camActor_0001", nil)
      self.fsm:SetProperty(BattleConst.BattleSkipCamera, _G.ObjectRefBoxing(camera))
      local cameraBone = self.fsm:GetProperty("camActor_0001_SA")
      self.fsm:SetProperty("camActor_0001_SA", nil)
      self.fsm:SetProperty(BattleConst.BattleSkipCameraAS, _G.ObjectRefBoxing(cameraBone))
    end
  end
  self.SkillObj = skill
  skill:SetPlayRate(0)
  NRCModeManager:DoCmd(BattleUIModuleCmd.OpenTransformLoadingUI)
  self.DelayOver = _G.DelayManager:DelaySeconds(1, self.Finish, self)
end

function BeastBeforeBattlePerform:SaveBlackboard(blackboard, name)
  FsmUtils.SaveAsProperty(self.fsm, blackboard, name)
end

function BeastBeforeBattlePerform:OnBattleEvent(event, value)
  if event == BattleEvent.TransformLoadingOpened then
    if self.SkillObj then
      self.SkillObj:SetPlayRate(1)
      self:Finish()
    end
    return true
  end
end

function BeastBeforeBattlePerform:ShowLevel()
  local levelStream = self.fsm:GetProperty("BeastLevelStream")
  if levelStream then
    levelStream:SetShouldBeVisible(true)
  end
end

function BeastBeforeBattlePerform:OnFinish()
  if self.DelayOver then
    _G.DelayManager:CancelDelayById(self.DelayOver)
    self.DelayOver = nil
  end
  if self.skillComponent then
    self.skillComponent:CancelSkill(self.SkillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
    self.skillComponent = nil
  end
  self.SkillObj = nil
  self:ShowLevel()
  BattleEventCenter:UnBind(self)
end

return BeastBeforeBattlePerform
