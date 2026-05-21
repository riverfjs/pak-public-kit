local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionState")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local DialogueTimelineWaitUserClickState = Base:Extend("DialogueTimelineWaitUserClickState")
FsmUtils.MergeMembers(Base, DialogueTimelineWaitUserClickState, {
  {
    name = "Keys",
    default = {},
    display_name = "\229\133\179\233\148\174\229\184\167"
  }
})

function DialogueTimelineWaitUserClickState:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueTimelineWaitUserClickState:OnEnter()
  self:InjectProperties()
  self.ParentModule = self.fsm:GetProperty("ParentModule")
  self.CurrentDialogue = self.fsm:GetProperty("CurrentDialogue")
  if self.ParentModule then
    self.ParentModule:RegisterEvent(self, DialogueModuleEvent.DialogueClicked, self.OnUserClick)
    self.ParentModule:RegisterEvent(self, DialogueModuleEvent.DialogueTalkFinished, self.OnTalkFinished)
  end
  self.fsm:SetProperty("bClickIntercept", #self.Keys >= 2)
end

function DialogueTimelineWaitUserClickState:OnFinish()
  if self.ParentModule then
    self.ParentModule:UnRegisterEvent(self, DialogueModuleEvent.DialogueClicked)
    self.ParentModule:UnRegisterEvent(self, DialogueModuleEvent.DialogueTalkFinished)
  end
  self.fsm:SetProperty("bClickIntercept", false)
end

function DialogueTimelineWaitUserClickState:OnTalkFinished(DialogueConfOnPanel)
  if DialogueConfOnPanel and DialogueConfOnPanel.id ~= self.CurrentDialogue.id then
    Log.Error("dialogue id mismatch", DialogueConfOnPanel.id, self.CurrentDialogue.id)
    return
  end
  Log.DebugFormat("DialogueTimelineWaitUserClickState:OnTalkFinished")
  self:FastforwardState(0.0)
  self.fsm:SetProperty("bClickIntercept", false)
end

function DialogueTimelineWaitUserClickState:OnUserClick(DialogueConfOnPanel)
  Log.DebugFormat("DialogueTimelineWaitUserClickState:OnUserClick")
  if DialogueConfOnPanel and self.CurrentDialogue and DialogueConfOnPanel.id ~= self.CurrentDialogue.id then
    Log.Error("dialogue id mismatch", DialogueConfOnPanel.id, self.CurrentDialogue.id)
    return
  end
  if self.state then
    local CurTime = self.state.execTime
    for _, KeyTime in ipairs(self.Keys) do
      if KeyTime > CurTime then
        self:FastforwardState(KeyTime)
        if _ >= #self.Keys then
          self.fsm:SetProperty("bClickIntercept", false)
        end
        break
      end
    end
  end
end

function DialogueTimelineWaitUserClickState:FastforwardState(TargetTime)
  if TargetTime <= 0.0 then
    TargetTime = self.Keys[#self.Keys]
  end
  local CurTime = self.state.execTime
  local FastForwardTime = TargetTime - CurTime
  if FastForwardTime > 0.0 then
    Log.DebugFormat("DialogueTimelineWaitUserClickState:FastforwardState, %s, fastforward %f", self.name, FastForwardTime)
    self.fsm:OnTick(FastForwardTime + 1.0E-7)
  end
end

return DialogueTimelineWaitUserClickState
