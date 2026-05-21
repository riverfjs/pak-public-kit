local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local Base = DialogueActionBase
local TryOpenGlobalBlackAction = Base:Extend("TryOpenGlobalBlackAction")
FsmUtils.MergeMembers(Base, TryOpenGlobalBlackAction, {
  {
    name = "ParentModule",
    type = "var"
  },
  {
    name = "DialogueConf",
    type = "var"
  }
})

function TryOpenGlobalBlackAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function TryOpenGlobalBlackAction:OnEnter()
  self:InjectProperties()
  if self.DialogueConf then
    local bLastDialogue = 0 == #self.DialogueConf.select_ids and (not self.DialogueConf.next_dialog_id or self.DialogueConf.next_dialog_id <= 0)
    if bLastDialogue then
      local TaskIDs = _G.DataConfigManager:GetDialogueUsedByTaskConf(self.DialogueConf.id, true)
      if TaskIDs then
        for _, TaskID in ipairs(TaskIDs.task_id) do
          local Task = NRCModuleManager:DoCmd(TaskModuleCmd.getTaskByID, TaskID) or NRCModuleManager:DoCmd(TaskModuleCmd.GetHiddenTaskByID, TaskID)
          local bValidTask = nil ~= Task
          if bValidTask then
            local bShouldGlobalBlackScreenBlendIn = not self.ParentModule:HasPanel("DialogueBlack") or not self.ParentModule:IsInBlackScreen()
            local OptionConf = self.fsm:GetProperty("CurrentOption")
            local OptionConfID = OptionConf and OptionConf.config.id
            if OptionConfID then
              local bOpenGlobalBlack = NRCModuleManager:DoCmd(BlackScreenModuleCmd.OpenGlobalBlackScreenIfNeed, TaskID, bShouldGlobalBlackScreenBlendIn, self, self.OnGlobalBlackBlendInFinish, {OptionID = OptionConfID})
              if bOpenGlobalBlack then
                self.ParentModule:CloseButtonSkip()
                return
              end
            end
          end
        end
      end
    end
  end
  self:Finish()
end

function TryOpenGlobalBlackAction:OnGlobalBlackBlendInFinish()
  self:Finish()
end

return TryOpenGlobalBlackAction
