local NPCActionEvent = require("NewRoco.Modules.Core.NPC.Actions.NPCActionEvent")
local NPCActionFactory = require("NewRoco.Modules.Core.NPC.Actions.NPCActionFactory")
local PowerDashActionFactory = require("NewRoco.Modules.Core.NPC.Actions.PowerDashAction.PowerDashActionFactory")
local PowerDashActionEvent = require("NewRoco.Modules.Core.NPC.Actions.PowerDashAction.PowerDashActionEvent")
local NpcActionOperation = Class("NpcActionOperation")

function NpcActionOperation:Ctor(operation, syncComponent)
  self:SetOperation(operation, syncComponent)
end

function NpcActionOperation:SetOperation(operation, syncComponent)
  self.operation = operation
  self.syncComponent = syncComponent
  self.isExecuting = false
end

function NpcActionOperation:Execute()
  if self.isExecuting then
    Log.Error("\230\150\173\230\142\137\228\186\134")
    return
  end
  if self.operation == nil then
    Log.Error("\230\137\167\232\161\140\229\164\177\232\180\165\228\186\134")
    self:Finish()
    return
  end
  self:ForceFixCoordinate(200)
  local npc = self:GetTarget()
  if npc then
    local option_conf = _G.DataConfigManager:GetNpcOptionConf(self.operation.npc_action_info.option_id)
    local action
    if NPCActionFactory.Registry[option_conf.action.action_type] then
      if option_conf.action.action_type == Enum.ActionType.ACT_DIALOG then
        local DialogueConf = _G.DataConfigManager:GetDialogueConf(tonumber(option_conf.action.action_param1), true)
        if DialogueConf then
          action = NPCActionFactory:Get(nil, DialogueConf.action, nil, false, npc)
        end
      else
        local Option
        local InterComp = npc and npc.InteractionComponent
        if InterComp then
          Option = InterComp:GetOptionByID(self.operation.npc_action_info.option_id)
        end
        action = NPCActionFactory:Get(Option, option_conf.action, nil, false, npc)
      end
      if action then
        action:CacheSyncInfo(self.operation.npc_action_info)
        action:AddEventListener(self, NPCActionEvent.OnFinish, self.Finish)
        action:Execute(self.operation.operator_id, false)
      end
    else
      local DashOption = npc.InteractionComponent:GetPowerDashOption()
      action = PowerDashActionFactory:Get(DashOption, option_conf.action)
      action:AddEventListener(self, PowerDashActionEvent.OnFinish, self.Finish)
      action:CacheSyncInfo(self.operation.npc_action_info)
      action:SyncExecute()
    end
  else
    self:Finish()
  end
end

function NpcActionOperation:Finish()
  self.syncComponent:DealNextOperation()
end

function NpcActionOperation:GetTarget()
  local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.operation.npc_action_info.operation_target_id)
  return npc
end

function NpcActionOperation:GetPlayer()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self.operation.operator_id)
  return player
end

function NpcActionOperation:ForceFixCoordinate(Tolerance)
  local player = self:GetPlayer()
  local player_position = player:GetActorLocation()
  local operator_position = self.operation.npc_action_info.operator_location.pos
  if Tolerance < math.abs(player_position.X - operator_position.x) or Tolerance < math.abs(player_position.Y - operator_position.y) or Tolerance < math.abs(player_position.Z - operator_position.z) then
    Log.Warning("\232\183\157\231\166\187\229\164\170\232\191\156\228\186\134\239\188\140\229\191\133\233\161\187\229\135\186\233\135\141\230\139\179")
    player:SetActorLocation(UE4.FVector(operator_position.x, operator_position.y, operator_position.z))
  end
end

return NpcActionOperation
