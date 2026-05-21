local EventDispatcher = require("Common.EventDispatcher")
local NpcChallengeHandler = Class("NpcChallengeHandler")
NpcChallengeHandler.EventType = {ChallengeStateChange = 1}
local NpcChallengeObject = Class("NpcChallengeObject")

local function IsBattleFieldFinished(fieldItem, factionId)
  if not fieldItem then
    return false
  end
  return fieldItem.finish
end

function NpcChallengeObject:Ctor(id)
  self.battleFieldItems = {}
  local cfg = _G.DataConfigManager:GetSpecBattleUi(id, true)
  if cfg then
    for _, group in pairs(cfg.difficult_group) do
      self.battleFieldItems[group.difficult_id] = {}
    end
  end
  self.eventDispatcher = NRCClass()
  EventDispatcher():Attach(self.eventDispatcher)
end

function NpcChallengeObject:UpdateFieldItem(fieldItem)
  local changed = false
  if fieldItem then
    local curFieldItem = self.battleFieldItems[fieldItem.battle_id]
    if curFieldItem and curFieldItem.finish ~= fieldItem.finish then
      changed = true
      self.battleFieldItems[fieldItem.battle_id] = fieldItem
    end
  end
  return changed
end

function NpcChallengeObject:Refresh(fieldItems)
  if not fieldItems then
    return
  end
  local hasChanged = false
  if table.isArray(fieldItems) then
    for _, fieldItem in ipairs(fieldItems) do
      if self:UpdateFieldItem(fieldItem) then
        hasChanged = true
      end
    end
  else
    hasChanged = self:UpdateFieldItem(fieldItems)
  end
  if hasChanged then
    self.eventDispatcher:SendEvent(NpcChallengeHandler.EventType.ChallengeStateChange)
  end
end

function NpcChallengeObject:SetBattleFinished(difficultId)
  local fieldItem = {}
  fieldItem.battle_id = difficultId
  fieldItem.finish = true
  self:Refresh(fieldItem)
end

function NpcChallengeObject:IsBattleFinished(battleId)
  return IsBattleFieldFinished(self.battleFieldItems[battleId])
end

function NpcChallengeObject:IsAllBattleFinished()
  for _, fieldItem in pairs(self.battleFieldItems) do
    if not IsBattleFieldFinished(fieldItem) then
      return false
    end
  end
  return true
end

function NpcChallengeObject:AddEventListener(listener, eventType, handler)
  self.eventDispatcher:AddEventListener(listener, eventType, handler)
end

function NpcChallengeObject:RemoveEventListener(listener, eventType, handler)
  self.eventDispatcher:RemoveEventListener(listener, eventType, handler)
end

function NpcChallengeHandler:Ctor()
  self.challengeItems = {}
end

function NpcChallengeHandler:AddOrRefreshChallengeItem(challengeData)
  if not challengeData then
    return
  end
  local id = challengeData.id
  if id then
    local npcChallengeObject = self:GetOrAddChallengeItem(id)
    npcChallengeObject:Refresh(challengeData.battle_field_items)
    return npcChallengeObject
  end
end

function NpcChallengeHandler:GetChallengeItem(id)
  return self.challengeItems[id]
end

function NpcChallengeHandler:GetOrAddChallengeItem(id)
  local npcChallengeObject = self.challengeItems[id]
  if not npcChallengeObject then
    npcChallengeObject = NpcChallengeObject(id)
    self.challengeItems[id] = npcChallengeObject
  end
  return npcChallengeObject
end

return NpcChallengeHandler
