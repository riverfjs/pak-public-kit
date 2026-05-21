local Base = require("NewRoco.AI.BehaviorTree.LuaActionBase")
local LuaActionQueryNpcByCfgId = Base:Extend("LuaActionQueryNpcByCfgId")
local ai_npc_retrieval_interval = 1000 * (_G.DataConfigManager:GetNpcGlobalConfig("ai_npc_retrieval_interval", true).num or 3)
local last_npc_retrieval_time = 0

function LuaActionQueryNpcByCfgId:OnStart(owner)
  local currentTime = os.msTime()
  if currentTime - ai_npc_retrieval_interval < last_npc_retrieval_time then
    return self:Finish(false)
  end
  local selfNpc = owner.Npc
  last_npc_retrieval_time = currentTime
  local npcCfgId = self.NpcCfgId:GetValue(owner)
  local queryDis = self.QueryDis:GetValue(owner)
  local centerPos = owner.Npc:GetActorLocation()
  if self.CenterPos then
    local customCenter = self.CenterPos:GetValue(owner)
    if customCenter and customCenter ~= UE4Helper.ZeroVector and customCenter ~= UE4Helper.InvalidVector then
      centerPos = customCenter
    end
  end
  local resultNpc
  local minDist = queryDis
  local npcs = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetAllNPC)
  if not npcs or type(npcs) ~= "table" then
    Log.PrintScreenMsg("[LuaActionQueryNpcByCfgId] GetAllNPC Failed")
    return self:Finish(false)
  end
  for _, npc in pairs(npcs) do
    if selfNpc ~= npc and npc.config and npc.config.id == npcCfgId and npc.viewObj and not npc.isDestroy then
      local loc = npc:GetActorLocation()
      local dist = loc and UE.FVector.Dist(loc, centerPos) or queryDis
      if minDist > dist then
        resultNpc = npc
        minDist = dist
      end
    end
  end
  if resultNpc then
    local OutPos = resultNpc:GetActorLocation()
    local skipValidatePath = not self.ValidatePath or not self.ValidatePath:GetValue(owner)
    if skipValidatePath or UE.UNRCNavLibrary.Abs_TestPathBetween(owner, centerPos, OutPos, false) then
      self.OutNpcPos:SetValue(owner, OutPos)
      self.OutObject:SetValue(owner, resultNpc)
      return self:Finish(true)
    end
  end
  return self:Finish(false)
end

return LuaActionQueryNpcByCfgId
