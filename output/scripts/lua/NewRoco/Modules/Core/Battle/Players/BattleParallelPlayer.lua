local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleParallelPlayer = BattlePlayerBase:Extend()

function BattleParallelPlayer:Ctor()
  BattlePlayerBase.Ctor(self)
end

function BattleParallelPlayer:Reset()
  self.parallel_count = 0
  self.parallel_nodes = {}
end

function BattleParallelPlayer:Play(performNode)
  self:Reset()
  self.performNode = performNode
  self.performInfo = performNode:GetInfo()
  _G.BattleEventCenter:Bind(self, BattleEvent.ResonanceSkillFinish)
  self.parallel_nodes = self.performNode:GetParallelNodes()
  local parallel_perform_nodes = {}
  for _, node in ipairs(self.parallel_nodes) do
    local group = node.OwnerGroup
    local player = node:GetPlayer()
    if group and player then
      self.parallel_count = self.parallel_count + 1
      table.insert(parallel_perform_nodes, node)
    end
  end
  if ProtoEnum.BattlePerformType.BPT_FEATURE_RESONANCE == self.performInfo.type then
    _G.BattleEventCenter:Dispatch(BattleEvent.ShowResonanceTip)
  end
  self.parallel_count = #parallel_perform_nodes
  if self.parallel_count > 0 then
    for _, node in ipairs(parallel_perform_nodes) do
      local group = node.OwnerGroup
      group:PlayNode(node)
    end
  else
    self:Finish()
  end
end

function BattleParallelPlayer:OnBattleEvent(eventName, ...)
  if BattleEvent.ResonanceSkillFinish == eventName then
    local group_id = (...)
    if group_id == self.performInfo.group_id then
      self.parallel_count = self.parallel_count - 1
      if 0 == self.parallel_count then
        self:Finish()
      end
    end
  end
end

function BattleParallelPlayer:Finish()
  if self:GetRuntimeData("is_finish") then
    return
  end
  self:SetRuntimeData("is_finish", true)
  _G.BattleManager.battleRuntimeData:ReduceResonancePerform()
  self.performNode:PerformComplete()
  _G.BattleEventCenter:UnBind(self)
end

return BattleParallelPlayer
