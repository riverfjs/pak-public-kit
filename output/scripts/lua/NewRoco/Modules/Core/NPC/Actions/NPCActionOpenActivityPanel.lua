local Base = require("NewRoco.Modules.Core.NPC.Actions.NPCActionModelBase")
local NPCActionOpenActivityPanel = Base:Extend("NPCActionOpenActivityPanel")

function NPCActionOpenActivityPanel:ExecuteWithModel()
  local mainObjects = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_ACTIVITY_RECALL, true)
  if mainObjects and #mainObjects > 0 then
    for _, object in ipairs(mainObjects) do
      local recall_data = object:GetActivityData()
      if recall_data and recall_data.active then
        _G.NRCModuleManager:GetModule("ActivityModule").recallActivity_ids = table.deepCopy(_G.DataConfigManager:GetActivityRecallClassConf(recall_data.recall_class).subactivity_ids)
        self:Finish(true)
        break
      end
    end
  end
end

return NPCActionOpenActivityPanel
