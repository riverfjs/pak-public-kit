local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local Base = DialogueActionBase
local DialogueAutoBlackScreenAtEndAction = Base:Extend("DialogueAutoBlackScreenAtEndAction")
FsmUtils.MergeMembers(Base, DialogueAutoBlackScreenAtEndAction, {
  {
    name = "ParentModule",
    type = "var"
  }
})

function DialogueAutoBlackScreenAtEndAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueAutoBlackScreenAtEndAction:OnEnter()
  self:InjectProperties()
  self.ParentModule:CloseButtonSkip()
  local player = DialogueUtils.GetHero()
  if self.fsm:GetProperty("PlayerPosSyncBlocker") and player and player:IsInTogetherMove() and (not self.ParentModule:HasPanel("DialogueBlack") or not self.ParentModule:IsInBlackScreen()) then
    local DummyConf = {}
    DummyConf.ui_source_type = Enum.UIsourceType.UIT_BLACK
    DummyConf.speed = 0
    self.ParentModule:_OpenConfiggedPanel(DummyConf, self.ParentModule.PreUIType, nil, nil, self.OnDialogueBlackFadeIn, self)
    return
  end
  self:Finish()
end

function DialogueAutoBlackScreenAtEndAction:OnDialogueBlackFadeIn()
  self:Finish()
end

function DialogueAutoBlackScreenAtEndAction:OnFinish()
end

return DialogueAutoBlackScreenAtEndAction
