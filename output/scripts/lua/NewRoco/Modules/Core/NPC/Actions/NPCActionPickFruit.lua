local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local Base = NPCActionBase
local NPCActionPickFruit = Base:Extend("NPCActionPickFruit")

function NPCActionPickFruit:Execute(playerId, needSendReq)
  if not self.OwnerNpc then
    return
  end
  self.OwnerNpc:SetNotDestroyFlag(true)
  self.OwnerNpc.InteractionComponent:TryDisableInteraction()
  Base.Execute(self, playerId, needSendReq)
end

function NPCActionPickFruit:OnSubmit(rsp)
  Base.OnSubmit(self, rsp)
  if 0 == rsp.ret_info.ret_code then
    if self:GetPlayer().isLocal then
      self:SyncAction()
    end
    self:RunSequence()
  end
end

function NPCActionPickFruit:RunSequence()
  local OwnerView = self:GetOwnerNPCView()
  local Player = self:GetPlayer()
  if not OwnerView then
    self:Finish(false)
    return
  end
  local SkillPath = "/Game/ArtRes/Effects/G6Skill/SceneEffect/G6_Scene_Tree_Growth_disappear.G6_Scene_Tree_Growth_disappear"
  local Skill = RocoSkillProxy.Create(SkillPath, OwnerView.RocoSkill, PriorityEnum.Active_Player_Action)
  if not Skill then
    self:Finish(false)
    return
  end
  Skill:SetCaster(OwnerView)
  Skill:SetTargets({
    Player.viewObj
  })
  Skill:RegisterEventCallback("PreStart", self, self.OnSetupBlackboard)
  Skill:RegisterEventCallback("PreEnd", self, self.OnSkillFinished)
  Skill:RegisterEventCallback("End", self, self.OnSkillFinished)
  Skill:RegisterEventCallback("Interrupt", self, self.OnSkillFinished)
  Skill:PlaySkill()
end

function NPCActionPickFruit:OnSetupBlackboard(Name, Skill)
  local ContentID = self.OwnerNpc.serverData.npc_base.npc_content_cfg_id
  if ContentID and 0 ~= ContentID then
    local Conf = _G.DataConfigManager:GetFruitTreeConf(ContentID)
    if Conf then
      if 1 == Conf.book_id then
        Skill.Blackboard:SetValueAsString("MI_UI_Book01", "MI_UI_Book01")
      elseif 4 == Conf.book_id then
        Skill.Blackboard:SetValueAsString("MI_UI_Book02", "MI_UI_Book02")
      elseif 2 == Conf.book_id then
        Skill.Blackboard:SetValueAsString("MI_UI_Book03", "MI_UI_Book03")
      elseif 3 == Conf.book_id then
        Skill.Blackboard:SetValueAsString("MI_UI_Book04", "MI_UI_Book04")
      end
    end
  end
end

function NPCActionPickFruit:OnSkillFinished()
  self.OwnerNpc:SetNotDestroyFlag(false)
  self:Finish(true)
end

function NPCActionPickFruit:UpdateInfo(Info, Reconnect)
  Base.UpdateInfo(self, Info, Reconnect)
  if Reconnect and self.OwnerNpc then
    self.OwnerNpc:SetNotDestroyFlag(false)
    self.OwnerNpc.InteractionComponent:TryEnableInteraction()
  end
end

return NPCActionPickFruit
