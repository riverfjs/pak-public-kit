local Base = require("NewRoco.AI.BehaviorTree.LuaActionBase")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local LuaActionSceneCommand = Base:Extend("LuaActionSceneCommand")

function LuaActionSceneCommand:OnStart(AIController, ...)
  local args = {
    ...
  }
  local owner = AIController
  local DelayTime = self.DelayTime:GetValue(owner)
  if 0 == DelayTime then
    self:RunCommandInternal(owner)
  else
    self.DelayHandle = _G.DelayManager:DelaySeconds(DelayTime, self.RunCommandInternal, self, owner)
  end
end

function LuaActionSceneCommand:OnInterrupt()
  if self.DelayHandle then
    _G.DelayManager:CancelDelayById(self.DelayHandle)
    self.DelayHandle = nil
  end
end

function LuaActionSceneCommand:RunCommandInternal(Controller)
  local npc = Controller.Npc
  local CommandType = self.CommandType:GetValue(Controller)
  local CommandParam = 0
  if self.CommandParam ~= nil then
    CommandParam = self.CommandParam:GetValue(Controller)
  end
  local bIsReleaseCmd = CommandType == _G.Enum.NpcSceneCommandType.NSC_RELEASE
  if bIsReleaseCmd then
    Log.DebugFormat("[SceneAI] \232\161\140\228\184\186\230\160\145\233\148\128\230\175\129\232\135\170\232\186\171 %s", npc.config.name)
    npc:RequestRelease(CommandParam)
    npc.AIComponent.markRequestRelease = true
    return
  end
  local bPersistCmd = false
  bPersistCmd = bPersistCmd or CommandType == _G.Enum.NpcSceneCommandType.NSC_BOSS_SWITCH_SERVER_AI
  if npc:IsLocal() then
    return self:Finish(true)
  elseif CommandType == _G.Enum.NpcSceneCommandType.NSC_BOSS_SWITCH_CLIENT_AI then
    return self:Finish(true)
  else
    if not _G.ZoneServer:CanSendNetworkCmd() then
      self:Finish(false)
      return
    end
    if CommandType == _G.Enum.NpcSceneCommandType.NSC_UPLOAD_POS then
      npc.module.SceneAIManager:RequestReportPosition(npc)
    else
      local StringParam
      if CommandType == _G.Enum.NpcSceneCommandType.NSC_LLM_OVERWRITE_BT or CommandType == _G.Enum.NpcSceneCommandType.NSC_LLM_OVERWRITE_BT_START then
        StringParam = Controller:GetMfbbString("Global_LlmPetBehaviorId")
      end
      if not self.CullingCheck(CommandType, CommandParam, npc) then
        local info = _G.ProtoMessage:newClientAiCommandInfo()
        info.actor_id = npc:GetServerId()
        info.action_id = CommandType
        info.command_param = CommandParam
        info.string_param = StringParam
        npc:GetServerPosition(info.pos)
        _G.SceneAIUtils.GetSceneAIManager():EnqueueMessage_SceneCommand(info)
      end
    end
  end
  if not bPersistCmd then
    return self:Finish(true)
  end
end

function LuaActionSceneCommand.CullingCheck(CommandType, CommandParam, npc)
  if CommandType == _G.Enum.NpcSceneCommandType.NSC_ADD_LOGIC_STATUS then
    if npc.LogicStatusComponent then
      local HasStatus, _, _ = npc.LogicStatusComponent:GetStatus(CommandParam)
      if HasStatus then
        return true
      end
    end
  elseif CommandType == _G.Enum.NpcSceneCommandType.NSC_REMOVE_LOGIC_STATUS and npc.LogicStatusComponent then
    local HasStatus, _, _ = npc.LogicStatusComponent:GetStatus(CommandParam)
    if not HasStatus then
      return true
    end
  end
  return false
end

return LuaActionSceneCommand
