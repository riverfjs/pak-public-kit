local BattlePiecesPlaySkill = require("NewRoco.Modules.Core.Battle.BattleCore.Pieces.Instances.BattlePiecesPlaySkill")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local Base = BattlePiecesPlaySkill
local BattlePiecesBeastTeamEnterPerform = Base:Extend("BattlePiecesBeastTeamEnterPerform")

function BattlePiecesBeastTeamEnterPerform:Play(action, finishCallBack)
  self.TriggerAction = action
  self.FinishCallBack = finishCallBack
  self.isOver = false
  local BeastBoss = BattleUtils.GetTraceNpc()
  if not (BeastBoss and BeastBoss.npc) or not BeastBoss.npc.viewObj then
    self.skillPath = BattleConst.TeamPerEnterFarBattle
  else
    local conf = BattleUtils.GetBattleConfig()
    self.skillPath = conf and conf.transiton
    if string.IsNilOrEmpty(self.skillPath) then
      self.skillPath = BattleConst.TeamBeastPerEnterBattle
    end
  end
  BattleEventCenter:Bind(self, BattleEvent.OnSkillResLoaded, BattleEvent.TransformLoadingOpened)
  self.resList = {
    self.skillPath
  }
  Base.Play(self)
end

function BattlePiecesBeastTeamEnterPerform:OnResLoadFinish()
  if not self.TriggerAction or self.TriggerAction.finished then
    return
  end
  _G.NRCModuleManager:DoCmd(LegendaryBattleModuleCmd.OnEnterBattleLoading)
  NRCModeManager:GetCurMode():DisablePanelByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer or not localPlayer.viewObj then
    Log.Warning("There is no model in localPlayer !!!")
    self:Complete()
    return
  end
  local BeastBoss = BattleUtils.GetTraceNpc()
  if not (BeastBoss and BeastBoss.npc) or not BeastBoss.npc.viewObj then
    Log.Warning("There is no model in Target !!!")
    BeastBoss = localPlayer
  elseif self.skillPath == BattleConst.TeamPerEnterFarBattle then
    BeastBoss = localPlayer
  else
    BeastBoss = BeastBoss.npc
  end
  local skillComponent = localPlayer.viewObj.RocoSkill
  if not skillComponent then
    Log.Warning("There is no skillComponent")
    self:Complete()
    return
  end
  local MyCastObject = CastSkillObject.FromSkillResID(self.skillPath)
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
    Log.Error("zgx res is vaild!!", BattleConst.TeamBeastPerEnterBattle)
    self:SkillFinish()
  end
end

function BattlePiecesBeastTeamEnterPerform:SaveCamera(name, skill)
  if not self.TriggerAction or self.TriggerAction.finished then
    return
  end
  if skill then
    local blackboard = skill:GetBlackboard()
    if blackboard then
      self.TriggerAction:SaveBlackboard(blackboard, "camActor_0001")
      self.TriggerAction:SaveBlackboard(blackboard, "camActor_0001_SA")
      local camera = self.TriggerAction.fsm:GetProperty("camActor_0001")
      self.TriggerAction.fsm:SetProperty("camActor_0001", nil)
      self.TriggerAction.fsm:SetProperty(BattleConst.BattleSkipCamera, _G.ObjectRefBoxing(camera))
      local cameraBone = self.TriggerAction.fsm:GetProperty("camActor_0001_SA")
      self.TriggerAction.fsm:SetProperty("camActor_0001_SA", nil)
      self.TriggerAction.fsm:SetProperty(BattleConst.BattleSkipCameraAS, _G.ObjectRefBoxing(cameraBone))
    end
  end
  self.SkillObj = skill
  skill:SetPlayRate(0)
  NRCModeManager:DoCmd(BattleUIModuleCmd.OpenTransformLoadingUI)
  self:SafeDelaySeconds("d_Complete", 1, self.Complete, self)
end

function BattlePiecesBeastTeamEnterPerform:OnBattleEvent(event, value)
  Base.OnBattleEvent(self, event, value)
  if event == BattleEvent.TransformLoadingOpened then
    if self.SkillObj then
      self.SkillObj:SetPlayRate(1)
      self:Complete()
    end
    return true
  end
end

function BattlePiecesBeastTeamEnterPerform:SkillFinish(name, skill)
  self:Complete()
end

function BattlePiecesBeastTeamEnterPerform:OnComplete()
  if self.isOver then
    return
  end
  self.isOver = true
  BattleEventCenter:UnBind(self)
  if self.TriggerAction then
    self.TriggerAction:Finish()
    self.FinishCallBack(self.TriggerAction)
  end
  if self.skillComponent then
    self.skillComponent:CancelSkill(self.SkillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
    self.skillComponent = nil
  end
  self.TriggerAction = nil
  self.FinishCallBack = nil
  self.SkillObj = nil
end

return BattlePiecesBeastTeamEnterPerform
